/*
* count_distinct.c - alternative to COUNT(DISTINCT ...)
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

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

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
    
#else

#define GET_AGG_CONTEXT(fname, fcinfo, aggcontext)  \
    if (fcinfo->context && IsA(fcinfo->context, AggState)) {  \
        aggcontext = ((AggState *) fcinfo->context)->aggcontext;  \
    } else {  \
        elog(ERROR, "%s called in non-aggregate context", fname);  \
        aggcontext = NULL;  \
    }

#define CHECK_AGG_CONTEXT(fname, fcinfo)  \
    if (!(fcinfo->context &&  \
        (IsA(fcinfo->context, AggState))))  \
    {  \
        elog(ERROR, "%s called in non-aggregate context", fname);  \
    }

/* backward compatibility with 8.3 (macros copied mostly from src/include/access/tupmacs.h) */

#if SIZEOF_DATUM == 8

#define fetch_att(T,attbyval,attlen) \
( \
    (attbyval) ? \
    ( \
        (attlen) == (int) sizeof(Datum) ? \
            *((Datum *)(T)) \
        : \
      ( \
        (attlen) == (int) sizeof(int32) ? \
            Int32GetDatum(*((int32 *)(T))) \
        : \
        ( \
            (attlen) == (int) sizeof(int16) ? \
                Int16GetDatum(*((int16 *)(T))) \
            : \
            ( \
                AssertMacro((attlen) == 1), \
                CharGetDatum(*((char *)(T))) \
            ) \
        ) \
      ) \
    ) \
    : \
    PointerGetDatum((char *) (T)) \
)
#else                           /* SIZEOF_DATUM != 8 */

#define fetch_att(T,attbyval,attlen) \
( \
    (attbyval) ? \
    ( \
        (attlen) == (int) sizeof(int32) ? \
            Int32GetDatum(*((int32 *)(T))) \
        : \
        ( \
            (attlen) == (int) sizeof(int16) ? \
                Int16GetDatum(*((int16 *)(T))) \
            : \
            ( \
                AssertMacro((attlen) == 1), \
                CharGetDatum(*((char *)(T))) \
            ) \
        ) \
    ) \
    : \
    PointerGetDatum((char *) (T)) \
)
#endif   /* SIZEOF_DATUM == 8 */

#define att_addlength_pointer(cur_offset, attlen, attptr) \
( \
    ((attlen) > 0) ? \
    ( \
        (cur_offset) + (attlen) \
    ) \
    : (((attlen) == -1) ? \
    ( \
        (cur_offset) + VARSIZE_ANY(attptr) \
    ) \
    : \
    ( \
        AssertMacro((attlen) == -2), \
        (cur_offset) + (strlen((char *) (attptr)) + 1) \
    )) \
)

#define att_align_nominal(cur_offset, attalign) \
( \
    ((attalign) == 'i') ? INTALIGN(cur_offset) : \
     (((attalign) == 'c') ? (long) (cur_offset) : \
      (((attalign) == 'd') ? DOUBLEALIGN(cur_offset) : \
       ( \
            AssertMacro((attalign) == 's'), \
            SHORTALIGN(cur_offset) \
       ))) \
)
    
#endif

#define COMPUTE_CRC32(element) \
    INIT_CRC32(element.hash); \
    COMP_CRC32(element.hash, element.value, element.length); \
    FIN_CRC32(element.hash);

/* hash table parameters */
#define HTAB_INIT_BITS      2      /* initial number of significant bits */
#define HTAB_INIT_SIZE      4      /* initial hash table size is only 4 buckets (80 items) */
#define HTAB_MAX_SIZE       262144 /* maximal hash table size is 256k buckets */
#define HTAB_BUCKET_LIMIT   20     /* when to resize the table (average bucket size limit) */

#define HTAB_BUCKET_STEP    5       /* bucket growth step (number of elements, not bytes) */

/* Structures used to keep the data - bucket and hash table. */

/* A single value in the hash table, along with it's 32-bit hash (so that we
 * don't need to compute it over and over).
 * 
 * TODO Is it really efficient to keep the hash, or should we save a bit of memory
 * and recompute the hash every time?
 */
typedef struct hash_element_t {
    
    uint32  hash;   /* 32-bit hash of this particular element */
    uint32  length; /* length of the value (depends on the actual data type) */
    char   *value;  /* the value itself */
    
} hash_element_t;

/* A single bucket of the hash table - basically a simple list of items implemented
 * as an array (+length). This grows in steps (HTAB_BUCKET_STEP).
 */
typedef struct hash_bucket_t {
    
    uint32  nitems; /* items in this particular bucket */
    hash_element_t * items;   /* array of ITEMS */
    
} hash_bucket_t;

/* A hash table - a collection of buckets. */
typedef struct hash_table_t {
    
    uint16  nbits;      /* number of significant bits of the hash (HTAB_INIT_BITS by default) */
    uint32  nbuckets;   /* number of buckets (HTAB_INIT_SIZE), basically 2^nbits */
    uint32  nitems;     /* current number of elements of the hash table */
    
    hash_bucket_t *  buckets;
    
} hash_table_t;

/* prototypes */
PG_FUNCTION_INFO_V1(count_distinct_append_int32);
PG_FUNCTION_INFO_V1(count_distinct_append_int64);
PG_FUNCTION_INFO_V1(count_distinct);

Datum count_distinct_append_int32(PG_FUNCTION_ARGS);
Datum count_distinct_append_int64(PG_FUNCTION_ARGS);
Datum count_distinct(PG_FUNCTION_ARGS);

static bool add_element_to_table(hash_table_t * htab, hash_element_t element);
static bool element_exists_in_bucket(hash_table_t * htab, hash_element_t element, uint32 bucket);
static void resize_hash_table(hash_table_t * htab);
static hash_table_t * init_hash_table(void);

Datum
count_distinct_append_int32(PG_FUNCTION_ARGS)
{
    
    hash_table_t * htab;
    hash_element_t element;
    
    MemoryContext oldcontext;
    MemoryContext aggcontext;
    
    /* OK, we do want to skip NULL values altogether */
    if (PG_ARGISNULL(1)) {
        if (PG_ARGISNULL(0))
            PG_RETURN_NULL();
        else
            /* if there already is a state accumulated, don't forget it */
            PG_RETURN_DATUM(PG_GETARG_DATUM(0));
    }

    GET_AGG_CONTEXT("count_distinct_append_int32", fcinfo, aggcontext);

    oldcontext = MemoryContextSwitchTo(aggcontext);
        
    if (PG_ARGISNULL(0)) {
        htab = init_hash_table();
    } else {
        htab = (hash_table_t *)PG_GETARG_POINTER(0);
    }
    
    /* we can be sure the value is not null (see the check above) */
    
    /* prepare the element structure (hash + value) */
    element.length = sizeof(int32);
    element.value = palloc(sizeof(int32));
    *((int32*)element.value) = PG_GETARG_INT32(1);
    
    /* if it was not added, free the memory, otherwise check if we need to resize the table */
    if (! add_element_to_table(htab, element)) {
        pfree(element.value);
    } else if ((htab->nitems / htab->nbuckets > HTAB_BUCKET_LIMIT) && (htab->nbuckets*4 <= HTAB_MAX_SIZE)) {
        /* do we need to increase the hash table size? only if we have too many elements in a bucket
         * (on average) and the table is not too large already */
        resize_hash_table(htab);
    }
    
    MemoryContextSwitchTo(oldcontext);
    
    PG_RETURN_POINTER(htab);

}

Datum
count_distinct_append_int64(PG_FUNCTION_ARGS)
{
    
    hash_table_t * htab;
    hash_element_t element;
    
    MemoryContext oldcontext;
    MemoryContext aggcontext;
    
    /* OK, we do want to skip NULL values altogether */
    if (PG_ARGISNULL(1)) {
        if (PG_ARGISNULL(0))
            PG_RETURN_NULL();
        else
            /* if there already is a state accumulated, don't forget it */
            PG_RETURN_DATUM(PG_GETARG_DATUM(0));
    }

    GET_AGG_CONTEXT("count_distinct_append_int64", fcinfo, aggcontext);

    oldcontext = MemoryContextSwitchTo(aggcontext);
        
    if (PG_ARGISNULL(0)) {
        htab = init_hash_table();
    } else {
        htab = (hash_table_t *)PG_GETARG_POINTER(0);
    }
    
    /* we can be sure the value is not null (see the check above) */
    
    /* prepare the element structure (hash + value) */
    element.length = sizeof(int64);
    element.value = palloc(sizeof(int64));
    *((int64*)element.value) = PG_GETARG_INT64(1);
    
    /* if it was not added, free the memory, otherwise check if we need to resize the table */
    if (! add_element_to_table(htab, element)) {
        pfree(element.value);
    } else if ((htab->nitems / htab->nbuckets > HTAB_BUCKET_LIMIT) && (htab->nbuckets*4 <= HTAB_MAX_SIZE)) {
        /* do we need to increase the hash table size? only if we have too many elements in a bucket
         * (on average) and the table is not too large already */
        resize_hash_table(htab);
    }
    
    MemoryContextSwitchTo(oldcontext);
    
    PG_RETURN_POINTER(htab);

}

Datum
count_distinct(PG_FUNCTION_ARGS)
{
    
    hash_table_t * htab;
    
    CHECK_AGG_CONTEXT("count_distinct", fcinfo);
    
    if (PG_ARGISNULL(0)) {
        PG_RETURN_NULL();
    }
    
    htab = (hash_table_t *)PG_GETARG_POINTER(0);
    
    PG_RETURN_INT64(htab->nitems);

}

static
bool add_element_to_table(hash_table_t * htab, hash_element_t element) {
    
    uint32 bucket;
    
    /* compute the hash and keep only the first 4 bytes */
    COMPUTE_CRC32(element);

    /* get the bucket and then add the element to the bucket */
    bucket = ((1 << htab->nbits) - 1) & element.hash;
    
    /* not it's not, so let's add it to the hash table */
    if (! element_exists_in_bucket(htab, element, bucket)) {
    
        /* if there's no space in the bucket, resize it */
        if (htab->buckets[bucket].nitems == 0) {
            htab->buckets[bucket].items = palloc(HTAB_BUCKET_STEP * sizeof(hash_element_t));
        } else if (htab->buckets[bucket].nitems % HTAB_BUCKET_STEP == 0) {
            htab->buckets[bucket].items = repalloc(htab->buckets[bucket].items,
                                                (htab->buckets[bucket].nitems + HTAB_BUCKET_STEP) * sizeof(hash_element_t));
        }
        
        /* increase the element into the bucket */
        htab->buckets[bucket].items[htab->buckets[bucket].nitems] = element;
        htab->buckets[bucket].nitems += 1;
        htab->nitems += 1;
        
        return TRUE;
    
    }
    
    return FALSE;

}

static
bool element_exists_in_bucket(hash_table_t * htab, hash_element_t element, uint32 bucket) {
    
    int i;
    
    /* is the element already in the bucket? */
    for (i = 0; i < htab->buckets[bucket].nitems; i++) {
        if (htab->buckets[bucket].items[i].hash == element.hash) {
            if (memcmp(htab->buckets[bucket].items[i].value, element.value, element.length) == 0) {
                return TRUE;
            }
        }
    }
    
    return FALSE;
    
}

static
hash_table_t * init_hash_table() {
    
    hash_table_t * htab = (hash_table_t *)palloc(sizeof(hash_table_t));
    
    htab->nbits = HTAB_INIT_BITS;
    htab->nbuckets = HTAB_INIT_SIZE;
    htab->nitems = 0;
        
    /* the memory is zeroed */
    htab->buckets = (hash_bucket_t *)palloc0(sizeof(hash_bucket_t) * HTAB_INIT_SIZE);
    
    return htab;
    
}

static
void resize_hash_table(hash_table_t * htab) {
    
    int i, j;
    hash_bucket_t old_bucket;
    
    /* basic sanity checks */
    assert(htab != NULL); 
    assert((htab->nbuckets >= HTAB_INIT_SIZE) && (htab->nbuckets*4 <= HTAB_MAX_SIZE)); /* valid number of buckets */
    
    /* double the hash table size */
    htab->nbits += 2;
    
    htab->nitems = 0; /* we'll essentially re-add all the elements, which will set this back */
    htab->buckets = repalloc(htab->buckets, 4 * htab->nbuckets * sizeof(hash_bucket_t));
    
    /* but zero the new buckets, just to be sure (the size is in bytes) */
    memset(htab->buckets + htab->nbuckets, 0, 3*htab->nbuckets * sizeof(hash_bucket_t));
    
    /* now let's loop through the old buckets and re-add all the elements */
    for (i = 0; i < htab->nbuckets; i++) {

        if (htab->buckets[i].items == NULL) {
            continue;
        }
        
        /* keep the old values */
        old_bucket = htab->buckets[i];
        
        /* reset the bucket */
        htab->buckets[i].nitems = 0;
        htab->buckets[i].items  = NULL;
        
        for (j = 0; j < old_bucket.nitems; j++) {
            add_element_to_table(htab, old_bucket.items[j]);
        }
        
        /* and finally release the old bucket */
        pfree(old_bucket.items);
        
    }
    
    /* finally, let's update the number of buckets */
    htab->nbuckets *= 4;
    
}