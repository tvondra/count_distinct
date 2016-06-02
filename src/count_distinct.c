/*
 * count_distinct.c - alternative to COUNT(DISTINCT ...) and ARRAY_AGG(DISTINCT ...)
 * Copyright (C) Tomas Vondra, 2013
 *
 */

#include <assert.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>
#include <limits.h>

#include "postgres.h"
#include "utils/datum.h"
#include "utils/array.h"
#include "utils/lsyscache.h"
#include "utils/numeric.h"
#include "utils/builtins.h"
#include "catalog/pg_type.h"
#include "nodes/execnodes.h"
#include "access/tupmacs.h"
#include "utils/pg_crc.h"

PG_MODULE_MAGIC;

/* if set to 1, the table resize will be profiled */
#define DEBUG_PROFILE       0

#define GET_AGG_CONTEXT(fname, fcinfo, aggcontext)  \
    if (! AggCheckCallContext(fcinfo, &aggcontext)) {   \
        elog(ERROR, "%s called in non-aggregate context", fname);  \
    }

#define CHECK_AGG_CONTEXT(fname, fcinfo)  \
    if (! AggCheckCallContext(fcinfo, NULL)) {   \
        elog(ERROR, "%s called in non-aggregate context", fname);  \
    }

/* This count_distinct implementation uses a simple, partially sorted array.
 *
 * It's considerably simpler than the hash-table based version, and the main
 * goals of this design is to:
 *
 * (a) minimize the palloc overhead - the whole array is allocated as a whole,
 *     and thus has a single palloc header (while in the hash table, each
 *     bucket had at least one such header)
 *
 * (b) optimal L2/L3 cache utilization - once the hash table can't fit into
 *     the CPU caches, it get's considerably slower because of cache misses,
 *     and it's impossible to improve the hash implementation (because for
 *     large hash tables it naturally leads to cache misses)
 *
 * Hash tables are great when you need to immediately query the structure
 * (e.g. to immediately check whether the key is already in the table), but
 * in count_distint it's not really necessary. We can accumulate some elements
 * first (into a buffer), and then process all of them at once - this approach
 * improves the CPU cache hit ratios. Also, the palloc overhead is much lower.
 *
 * The data array is split into three sections - sorted items, unsorted items,
 * and unused.
 *
 *     ----------------------------------------------
 *     |    sorted    |    unsorted    |    free    |
 *     ----------------------------------------------
 *
 * Initially, the sorted / unsorted sections are empty, of course.
 *
 *     ----------------------------------------------
 *     |                    free                    |
 *     ----------------------------------------------
 *
 * New values are simply accumulated into the unsorted section, which grows.
 *
 *     ----------------------------------------------
 *     |          unsorted  -->       |     free    |
 *     ----------------------------------------------
 *
 * Once there's no more space for new items, the unsorted items are 'compacted'
 * which means the values are sorted, duplicates are removed and the result
 * is merged into the sorted section (unless it's empty). The 'merge' is just
 * a simple 'merge-sort' of the two sorted inputs, with removal of duplicates.
 *
 * Once the compaction completes, it's checked whether enough space was freed,
 * where 'enough' means ~20% of the array needs to be free. Using low values
 * (e.g. space for at least one value) might cause 'oscillation' - imagine
 * compaction that removes a single item, causing compaction on the very next
 * addition. Using non-trivial threshold (like the 20%) should prevent such
 * frequent compactions - which is quite expensive operation.
 *
 * If there's not enough free space, the array grows (twice the size).
 *
 * The compaction needs to be performed at the very end, when computing the
 * actual result of the aggregate (distinct value in the array).
 *
 */

#define ARRAY_INIT_SIZE     32      /* initial size of the array (in bytes) */
#define ARRAY_FREE_FRACT    0.2     /* we want >= 20% free space after compaction */

/* A hash table - a collection of buckets. */
typedef struct element_set_t {

    uint32  item_size;      /* length of the value (depends on the actual data type) */
    uint32  nsorted;        /* number of items in the sorted part (distinct) */
    uint32  nall;           /* number of all items (unsorted part may contain duplicates) */
    uint32  nbytes;         /* number of bytes in the data array */
    bool    input_is_array; /* flag if input type is array */
    char    typalign;       /* alignment type, used only if input is array */

    /* aggregation memory context (reference, so we don't need to do lookups repeatedly) */
    MemoryContext aggctx;

    /* elements */
    char *  data;           /* nsorted items first, then (nall - nsorted) unsorted items */

} element_set_t;


/* prototypes */
PG_FUNCTION_INFO_V1(count_distinct_append);
PG_FUNCTION_INFO_V1(count_distinct);
PG_FUNCTION_INFO_V1(array_agg_distinct);

static void add_element(element_set_t * eset, char * value);
static element_set_t *init_set(bool input_is_array, int typalign, int item_size, MemoryContext ctx);
static int compare_items(const void * a, const void * b, void * size);
static void compact_set(element_set_t * eset, bool need_space);

#if DEBUG_PROFILE
static void print_set_stats(element_set_t * eset);
#endif

Datum
count_distinct_append(PG_FUNCTION_ARGS)
{
    element_set_t  *eset;

    /* info for anyelement */
    Oid         input_type = get_fn_expr_argtype(fcinfo->flinfo, 1);

    /* memory contexts */
    MemoryContext oldcontext;
    MemoryContext aggcontext;

    /* OK, we do want to skip NULL values altogether */
    if (PG_ARGISNULL(1) && PG_ARGISNULL(0)) /* both values are NULL*/
        PG_RETURN_NULL();   /* no state, no value -> just keep NULL */
    else if (PG_ARGISNULL(1))
        /* if there already is a state accumulated, don't forget it */
        PG_RETURN_DATUM(PG_GETARG_DATUM(0));

    /* we can be sure the value is not null (see the check above) */

    /* switch to the per-group hash-table memory context */
    GET_AGG_CONTEXT("count_distinct_append", fcinfo, aggcontext);

    oldcontext = MemoryContextSwitchTo(aggcontext);

    /* init the hash table, if needed */
    if (PG_ARGISNULL(0))
    {
        int16       typlen;
        bool        typbyval;
        char        typalign;
        Oid         element_type;
        bool        input_is_array;
        
        /* check if input type is array */
        element_type = get_element_type(input_type);
        input_is_array = OidIsValid(element_type);
        if (!input_is_array)
            element_type = input_type;
        
        /* get type information for the second parameter (anyelement item) */
        get_typlenbyvalalign(element_type, &typlen, &typbyval, &typalign);

        /* we can't handle varlena types yet or values passed by reference */
        if ((typlen == -1) || (! typbyval))
            elog(ERROR, "count_distinct handles only fixed-length types passed by value or arrays of such types");
            
        eset = init_set(input_is_array, typalign, typlen, aggcontext);
    } else
        eset = (element_set_t *)PG_GETARG_POINTER(0);

    if (eset->input_is_array) /* input is array */
    {
        ArrayType *   input = PG_GETARG_ARRAYTYPE_P(1);
        int           ndims = ARR_NDIM(input);
        int       *    dims = ARR_DIMS(input);
        int          nitems = ArrayGetNItems(ndims, dims);
        bits8     *  bitmap = ARR_NULLBITMAP(input);
        int         bitmask = 1;
        char      * arr_ptr = ARR_DATA_PTR(input);
        int               i;

        for (i = 0; i < nitems; i++)
        {
            Datum   itemvalue;

            /* Ignore NULLs */
            if (bitmap && (*bitmap & bitmask) == 0)
                continue;

            itemvalue = fetch_att(arr_ptr, true, eset->item_size);
            
            add_element(eset, (char*)&itemvalue);
            
            /* advance array pointer */
            arr_ptr = att_addlength_pointer(arr_ptr, eset->item_size, arr_ptr);
            arr_ptr = (char *) att_align_nominal(arr_ptr, eset->typalign);

            /* advance bitmap pointer if any */
            if (bitmap)
            {
                bitmask <<= 1;
                if (bitmask == 0x100)
                {
                    bitmap++;
                    bitmask = 1;
                }
            }
        }
    }
    else /*input is non-array*/
    {
        Datum input = PG_GETARG_DATUM(1);
        /* add the value into the set */
        add_element(eset, (char*)&input);
    }

    MemoryContextSwitchTo(oldcontext);

    PG_RETURN_POINTER(eset);
}

Datum
array_agg_distinct(PG_FUNCTION_ARGS)
{
    element_set_t * eset;
    Datum * array_of_datums;
    int i;

    /* type information for the dummy second parameter (anyelement item) */
    Oid         input_type,
                element_type;
    int16       typlen;
    bool        typbyval;
    char        typalign;

    CHECK_AGG_CONTEXT("count_distinct", fcinfo);

    /* get element type for the dummy second parameter (anyarray/anynonarray item) */
    input_type = get_fn_expr_argtype(fcinfo->flinfo, 1);
    element_type = get_element_type(input_type);
    if (!OidIsValid(element_type))
        element_type = input_type;

    /* return empty array if the state was not initialized */
    if (PG_ARGISNULL(0))
        PG_RETURN_DATUM(PointerGetDatum(construct_empty_array(element_type)));

    eset = (element_set_t *)PG_GETARG_POINTER(0);

    /* get detailed type information on the element type */
    get_typlenbyvalalign(element_type, &typlen, &typbyval, &typalign);

    /* do the compaction */
    compact_set(eset, false);

#if DEBUG_PROFILE
    print_set_stats(eset);
#endif

    /* Copy data from compact array to a transitional array of Datums
     * A bit suboptimal way, spends excessive memory and performs extra data copy operation.
     * Could be rewritten in low level using ArrayCastAndSet
     */
    array_of_datums = palloc0(eset->nsorted * sizeof(Datum));
    for (i = 0; i < eset->nsorted; i++)
        memcpy(array_of_datums + i, eset->data + (eset->item_size * i), eset->item_size);
        
    /* build and return the array */
    PG_RETURN_DATUM(PointerGetDatum(construct_array(
        array_of_datums, eset->nsorted, element_type, typlen, typbyval, typalign
    )));
}

Datum
count_distinct(PG_FUNCTION_ARGS)
{

    element_set_t * eset;

    CHECK_AGG_CONTEXT("count_distinct", fcinfo);

    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    eset = (element_set_t *)PG_GETARG_POINTER(0);

    /* do the compaction */
    compact_set(eset, false);

#if DEBUG_PROFILE
    print_set_stats(eset);
#endif

    PG_RETURN_INT64(eset->nall);

}

/* performs compaction of the set
 *
 * Sorts the unsorted data, removes duplicate values and then merges it
 * into the already sorted part (skipping duplicate values).
 *
 * Finally, it checks whether at least ARRAY_FREE_FRACT (20%) of the array
 * is empty, and if not then resizes it.
 */
static void
compact_set(element_set_t * eset, bool need_space)
{
    char   *base = eset->data + (eset->nsorted * eset->item_size);
    char   *last = base;
    char   *curr;
    int     i;
    int     cnt = 1;
    double  free_fract;

    Assert(eset->nsorted + eset->nall > 0);
    Assert(eset->data != NULL);
    Assert(eset->nsorted <= eset->nall);
    Assert(eset->nall * eset->item_size <= eset->nbytes);

    /* if there are no new (unsorted) items, we're done */
    if (eset->nall == eset->nsorted)
        return;

    /* sort the new items
     *
     * TODO Consider replacing this insert-sort for small number of items (for <64 items
     *      it might be faster than qsort)
     */
    qsort_arg(eset->data + eset->nsorted * eset->item_size,
              eset->nall - eset->nsorted, eset->item_size,
              compare_items, &eset->item_size);

    /*
     * Remove duplicities from the sorted array. That is - walk through the array,
     * compare each item with the previous one, and only keep it if it's different.
     */
    for (i = 1; i < eset->nall - eset->nsorted; i++)
    {
        curr = base + (i * eset->item_size);

        /* items differ (keep the item) */
        if (memcmp(last, curr, eset->item_size) != 0)
        {

            last += eset->item_size;
            cnt  += 1;

            /* only copy if really needed */
            if (last != curr)
                memcpy(last, curr, eset->item_size);
        }
    }

    /* duplicities removed -> update the number of items in this part */
    eset->nall = eset->nsorted + cnt;


    /* If this is the first sorted part, we can just use it as the 'sorted' part. */
    if (eset->nsorted == 0)
        eset->nsorted = eset->nall;

    /* TODO Another optimization opportunity is that we don't really need to merge the
     *      arrays, if we freed enough space by processing the new items. We may postpone
     *      that until the last call (when finalizing the aggregate). OTOH if that happens,
     *      it shouldn't be that expensive to merge because the number of new items will
     *      be small (as we've removed a enough duplicities).
     */

    /* If a merge is needed, walk through the arrays and keep unique values. */
    if (eset->nsorted < eset->nall)
    {
        MemoryContext oldctx = MemoryContextSwitchTo(eset->aggctx);

        /* allocate new array for the result */
        char * data = palloc0(eset->nbytes);
        char * ptr = data;

        /* already sorted array */
        char * a = eset->data;
        char * a_max = eset->data + eset->nsorted * eset->item_size;

        /* the new array */
        char * b = eset->data + (eset->nsorted * eset->item_size);
        char * b_max = eset->data + eset->nall * eset->item_size;

        MemoryContextSwitchTo(oldctx);

        /* TODO There's a possibility for optimization - if we get already sorted
         *      items (e.g. because of a subplan), we can just copy the arrays.
         *      The check is as simple as (a_first > b_last) || (a_last < b_first).
         *      OTOH this might be pointless in practice.
         */

        while (true)
        {

            int r = memcmp(a, b, eset->item_size);

            /*
             * If both values are the same, copy one of them into the result and increment
             * both. Otherwise, increment only the smaller value.
             */
            if (r == 0)
            {
                memcpy(ptr, a, eset->item_size);
                a += eset->item_size;
                b += eset->item_size;
            }
            else if (r < 0)
            {
                memcpy(ptr, a, eset->item_size);
                a += eset->item_size;
            }
            else
            {
                memcpy(ptr, b, eset->item_size);
                b += eset->item_size;
            }

            ptr += eset->item_size;

            /*
             * If we reached the end of (at least) one of the arrays, copy all the remaining
             * items and we're done.
             */
            if ((a == a_max) || (b == b_max))
            {

                if (a != a_max)         /* b ended -> copy rest of a */
                {
                    memcpy(ptr, a, a_max - a);
                    ptr += (a_max - a);
                }
                else if (b != b_max)    /* a ended -> copy rest of b */
                {
                    memcpy(ptr, b, b_max - b);
                    ptr += (b_max - b);
                }

                break;

            }

        }

        /* update the counts */
        eset->nsorted = (ptr - data) / eset->item_size;
        eset->nall = eset->nsorted;
        pfree(eset->data);
        eset->data = data;

    }

    /* free space as a fraction of the total size */
    free_fract = (eset->nbytes - eset->nall * eset->item_size) * 1.0 / eset->nbytes;

    /*
     * When we need space for more items (e.g. not when finalizing the aggregate
     * result) we need to check that, and enlarge the array when needed. We
     * require ARRAY_FREE_FRACT of the space to be free.
     */
    if (need_space && (free_fract < ARRAY_FREE_FRACT))
    {
        eset->nbytes *= 2;
        eset->data = repalloc(eset->data, eset->nbytes);
    }
}

static void
add_element(element_set_t * eset, char * value)
{
    /* if there's not enough space for another item, perform compaction */
    if (eset->item_size * (eset->nall + 1) > eset->nbytes)
        compact_set(eset, true);

    /* there needs to be space for at least one more value (thanks to the compaction) */
    Assert(eset->nbytes >= eset->item_size * (eset->nall + 1));

    /* now we're sure there's enough space */
    memcpy(eset->data + (eset->item_size * eset->nall), value, eset->item_size);
    eset->nall += 1;
}

/* XXX make sure the whole method is called within the aggregate context */
static element_set_t *
init_set(bool input_is_array, int typalign, int item_size, MemoryContext ctx)
{
    element_set_t * eset = (element_set_t *)palloc0(sizeof(element_set_t));

    eset->item_size = item_size;
    eset->nsorted = 0;
    eset->nall = 0;
    eset->nbytes = ARRAY_INIT_SIZE;
    eset->aggctx = ctx;
    eset->input_is_array = input_is_array;
    eset->typalign = typalign;

    /* the memory is zeroed */
    eset->data = palloc0(eset->nbytes);

    return eset;
}

#if DEBUG_PROFILE
static void
print_set_stats(element_set_t * eset)
{
    elog(WARNING, "bytes=%d item=%d all=%d sorted=%d", eset->nbytes, eset->item_size, eset->nall, eset->nsorted);
}
#endif

/* just compare the data directly */
static int
compare_items(const void * a, const void * b, void * size)
{
    return memcmp(a, b, *(int*)size);
}
