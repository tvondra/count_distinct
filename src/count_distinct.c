/*
 * count_distinct.c - alternative to COUNT(DISTINCT ...)
 * Copyright (C) Tomas Vondra, 2013 - 2016
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

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

/* if set to 1, the table resize will be profiled */
#define DEBUG_PROFILE       0

#if (PG_VERSION_NUM >= 90000)

#define GET_AGG_CONTEXT(fname, fcinfo, aggcontext)  \
    if (! AggCheckCallContext(fcinfo, &aggcontext)) {   \
        elog(ERROR, "%s called in non-aggregate context", fname);  \
    }

#define CHECK_AGG_CONTEXT(fname, fcinfo)  \
    if (! AggCheckCallContext(fcinfo, NULL)) {   \
        elog(ERROR, "%s called in non-aggregate context", fname);  \
    }

#elif (PG_VERSION_NUM >= 80400)

#define GET_AGG_CONTEXT(fname, fcinfo, aggcontext)  \
    if (fcinfo->context && IsA(fcinfo->context, AggState)) {  \
        aggcontext = ((AggState *) fcinfo->context)->aggcontext;  \
    } else if (fcinfo->context && IsA(fcinfo->context, WindowAggState)) {  \
        aggcontext = ((WindowAggState *) fcinfo->context)->wincontext;  \
    } else {  \
        elog(ERROR, "%s called in non-aggregate context", fname);  \
        aggcontext = NULL;  \
    }

#define CHECK_AGG_CONTEXT(fname, fcinfo)  \
    if (!(fcinfo->context &&  \
        (IsA(fcinfo->context, AggState) ||  \
        IsA(fcinfo->context, WindowAggState))))  \
    {  \
        elog(ERROR, "%s called in non-aggregate context", fname);  \
    }

#endif

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

    uint32  item_size;  /* length of the value (depends on the actual data type) */
    uint32  nsorted;    /* number of items in the sorted part (distinct) */
    uint32  nall;       /* number of all items (unsorted part may contain duplicates) */
    uint32  nbytes;     /* number of bytes in the data array */

    /* used for arrays only (cache for get_typlenbyvalalign results) */
    char    typalign;

    /* aggregation memory context (reference, so we don't need to do lookups repeatedly) */
    MemoryContext aggctx;

    /* elements */
    char *  data;       /* nsorted items first, then (nall - nsorted) unsorted items */

} element_set_t;


/* prototypes */
PG_FUNCTION_INFO_V1(count_distinct_append);
PG_FUNCTION_INFO_V1(count_distinct_elements_append);
PG_FUNCTION_INFO_V1(count_distinct);

Datum count_distinct_append(PG_FUNCTION_ARGS);
Datum count_distinct_elements_append(PG_FUNCTION_ARGS);
Datum count_distinct(PG_FUNCTION_ARGS);

static void add_element(element_set_t * eset, char * value);
static element_set_t *init_set(int item_size, char typalign, MemoryContext ctx);
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
    Oid         element_type = get_fn_expr_argtype(fcinfo->flinfo, 1);
    Datum       element = PG_GETARG_DATUM(1);

    /* memory contexts */
    MemoryContext oldcontext;
    MemoryContext aggcontext;

    /*
     * If the new value is NULL, we simply return the current aggregate state
     * (it might be NULL, so check it).
     */
    if (PG_ARGISNULL(1) && PG_ARGISNULL(0))
        PG_RETURN_NULL();
    else if (PG_ARGISNULL(1))
        PG_RETURN_DATUM(PG_GETARG_DATUM(0));

    /* from now on we know the new value is not NULL */

    /* switch to the per-group hash-table memory context */
    GET_AGG_CONTEXT("count_distinct_append", fcinfo, aggcontext);

    oldcontext = MemoryContextSwitchTo(aggcontext);

    /* init the hash table, if needed */
    if (PG_ARGISNULL(0))
    {
        int16       typlen;
        bool        typbyval;
        char        typalign;

        /* get type information for the second parameter (anyelement item) */
        get_typlenbyvalalign(element_type, &typlen, &typbyval, &typalign);

        /* we can't handle varlena types yet or values passed by reference */
        if ((typlen < 0) || (! typbyval))
            elog(ERROR, "count_distinct handles only fixed-length types passed by value");

        eset = init_set(typlen, typalign, aggcontext);
    } else
        eset = (element_set_t *)PG_GETARG_POINTER(0);

    /* add the value into the set */
    add_element(eset, (char*)&element);

    MemoryContextSwitchTo(oldcontext);

    PG_RETURN_POINTER(eset);
}

Datum
count_distinct_elements_append(PG_FUNCTION_ARGS)
{
    int             i;
    element_set_t  *eset;

    /* info for anyarray */
    Oid input_type;
    Oid element_type;

    /* array data */
    ArrayType  *input;
    int         ndims;
    int        *dims;
    int         nitems;
    bits8      *null_bitmap;
    char       *arr_ptr;
    Datum       element;

    /* memory contexts */
    MemoryContext oldcontext;
    MemoryContext aggcontext;

    /*
     * If the new value is NULL, we simply return the current aggregate state
     * (it might be NULL, so check it). In this case we don't really care about
     * the types etc.
     *
     * We may still get NULL elements in the array, but to check that we would
     * have to walk the array, which does not qualify as cheap check. Also we
     * assume that there's at least one non-NULL element, and we'll walk the
     * array just once. It's possible we'll get empty set this way.
     */
    if (PG_ARGISNULL(1) && PG_ARGISNULL(0))
        PG_RETURN_NULL();
    else if (PG_ARGISNULL(1))
        PG_RETURN_DATUM(PG_GETARG_DATUM(0));

    /* from now on we know the new value is not NULL */

    /* get the type of array elements */
    input_type = get_fn_expr_argtype(fcinfo->flinfo, 1);
    element_type = get_element_type(input_type);

    /*
     * parse the array contents (we know we got non-NULL value)
     *
     * XXX Should this handle arrays with multiple dimensions?
     */
    input = PG_GETARG_ARRAYTYPE_P(1);
    ndims = ARR_NDIM(input);
    dims = ARR_DIMS(input);
    nitems = ArrayGetNItems(ndims, dims);
    null_bitmap = ARR_NULLBITMAP(input);
    arr_ptr = ARR_DATA_PTR(input);

    /* make sure we're running as part of aggregate function */
    GET_AGG_CONTEXT("count_distinct_elements_append", fcinfo, aggcontext);

    oldcontext = MemoryContextSwitchTo(aggcontext);

    /* init the hash table, if needed */
    if (PG_ARGISNULL(0))
    {
        int16       typlen;
        bool        typbyval;
        char        typalign;

        /* get type information for the second parameter (anyelement item) */
        get_typlenbyvalalign(element_type, &typlen, &typbyval, &typalign);

        /* we can't handle varlena types yet or values passed by reference */
        if ((typlen < 0) || (! typbyval))
            elog(ERROR, "count_distinct_elements handles only arrays of fixed-length types passed by value");

        eset = init_set(typlen, typalign, aggcontext);
    }
    else
        eset = (element_set_t *)PG_GETARG_POINTER(0);

    /* add all array elements to the set */
    for (i = 0; i < nitems; i++)
    {
        /* ignore nulls */
        if (null_bitmap && !(null_bitmap[i / 8] & (1 << (i % 8))))
            continue;

        element = fetch_att(arr_ptr, true, eset->item_size);

        add_element(eset, (char*)&element);

        /* advance array pointer */
        arr_ptr = att_addlength_pointer(arr_ptr, eset->item_size, arr_ptr);
        arr_ptr = (char *) att_align_nominal(arr_ptr, eset->typalign);
    }

    MemoryContextSwitchTo(oldcontext);

    PG_RETURN_POINTER(eset);
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

/*
 * performs compaction of the sorted set
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
    int        i;
    int        cnt = 1;
    double    free_fract;

    Assert(eset->nsorted + eset->nall > 0);
    Assert(eset->data != NULL);
    Assert(eset->nsorted <= eset->nall);
    Assert(eset->nall * eset->item_size <= eset->nbytes);

    /* if there are no new (unsorted) items, we're done */
    if (eset->nall == eset->nsorted)
        return;

    /*
     * sort the array with new items
     *
     * TODO Consider replacing this insert-sort for small number of items
     * (for <64 items it might be faster than qsort)
     */
    qsort_arg(eset->data + eset->nsorted * eset->item_size,
              eset->nall - eset->nsorted, eset->item_size,
              compare_items, &eset->item_size);

    /*
     * Remove duplicate values from the sorted array. That is - walk through
     * the array, compare each item with the preceding one, and only keep it
     * if they differ. We skip the first value, as it's always unique (there
     * is no preceding value it might be equal to).
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

    /*
     * TODO Another optimization opportunity is that we don't really need to
     *        merge the arrays, if we freed enough space by processing the new
     *        items. We may postpone that until the last call (when finalizing
     *        the aggregate). OTOH if that happens, it shouldn't be that
     *        expensive to merge because the number of new items will be small
     *        (as we've removed a enough duplicities). But we still need to
     *        shuffle the data around, which wastes memory bandwidth.
     */

    /* If a merge is needed, walk through the arrays and keep unique values. */
    if (eset->nsorted < eset->nall)
    {
        MemoryContext oldctx = MemoryContextSwitchTo(eset->aggctx);

        /* allocate new array for the result */
        char * data = palloc(eset->nbytes);
        char * ptr = data;

        /* already sorted array */
        char * a = eset->data;
        char * a_max = eset->data + eset->nsorted * eset->item_size;

        /* the new array */
        char * b = eset->data + (eset->nsorted * eset->item_size);
        char * b_max = eset->data + eset->nall * eset->item_size;

        MemoryContextSwitchTo(oldctx);

        /*
         * TODO There's a possibility for optimization - if we get already
         *        sorted items (e.g. because of a subplan), we can just copy the
         *        arrays. The check is as simple as checking
         *
         *        (a_first > b_last) || (a_last < b_first).
         *
         *        OTOH this is probably very unlikely to happen in practice.
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
             * If we reached the end of (at least) one of the arrays, copy all
             * the remaining items and we're done.
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

        Assert((ptr - data) <= (eset->nall * eset->item_size));

        /*
         * Update the counts with the result of the merge (there might be
         * duplicities between the two parts, and we have eliminated them).
         */
        eset->nsorted = (ptr - data) / eset->item_size;
        eset->nall = eset->nsorted;
        pfree(eset->data);
        eset->data = data;
    }

    /* compute free space as a fraction of the total size */
    free_fract
        = (eset->nbytes - eset->nall * eset->item_size) * 1.0 / eset->nbytes;

    /*
     * If we need space for more items (e.g. not when finalizing the aggregate
     * result), enlarge the array when needed. We require ARRAY_FREE_FRACT of
     * the space to be free.
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
    /*
     * If there's not enough space for another item, perform compaction
     * (this also allocates enough free space for new entries).
     */
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
init_set(int item_size, char typalign, MemoryContext ctx)
{
    element_set_t * eset = (element_set_t *)palloc(sizeof(element_set_t));

    eset->item_size = item_size;
    eset->typalign = typalign;
    eset->nsorted = 0;
    eset->nall = 0;
    eset->nbytes = ARRAY_INIT_SIZE;
    eset->aggctx = ctx;

    eset->data = palloc(eset->nbytes);

    return eset;
}

#if DEBUG_PROFILE
static void
print_set_stats(element_set_t * eset)
{
    elog(WARNING, "bytes=%d item=%d all=%d sorted=%d",
                  eset->nbytes, eset->item_size, eset->nall, eset->nsorted);
}
#endif

/* just compare the data directly using memcmp */
static int
compare_items(const void * a, const void * b, void * size)
{
    return memcmp(a, b, *(int*)size);
}
