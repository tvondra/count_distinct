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
#include "utils/array.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "access/tupmacs.h"

PG_MODULE_MAGIC;

/* if set to 1, the table resize will be profiled */
#define DEBUG_PROFILE	   0

#define GET_AGG_CONTEXT(fname, fcinfo, aggcontext)  \
	if (! AggCheckCallContext(fcinfo, &aggcontext)) {   \
		elog(ERROR, "%s called in non-aggregate context", fname);  \
	}

#define CHECK_AGG_CONTEXT(fname, fcinfo)  \
	if (! AggCheckCallContext(fcinfo, NULL)) {   \
		elog(ERROR, "%s called in non-aggregate context", fname);  \
	}

/*
 * This count_distinct implementation uses a simple, partially sorted array.
 *
 * It's considerably simpler than the hash-table based version, and the main
 * goals of this design is to:
 *
 * (a) minimize the palloc overhead - the whole array is allocated as a whole,
 *	 and thus has a single palloc header (while in the hash table, each
 *	 bucket had at least one such header)
 *
 * (b) optimal L2/L3 cache utilization - once the hash table can't fit into
 *	 the CPU caches, it get's considerably slower because of cache misses,
 *	 and it's impossible to improve the hash implementation (because for
 *	 large hash tables it naturally leads to cache misses)
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
 */
typedef struct element_set_t
{
	/* aggregation memory context (so we don't need to do lookups repeatedly) */
	MemoryContext	aggctx;

	Size	nbytes;		/* size of the data array (number of bytes) */
	uint32	nsorted;	/* number of items in the sorted part */
	uint32	nall;		/* number of all items (sorted + unsorted) */

	/* used for arrays only (cache for get_typlenbyvalalign results) */
	int16	typlen;
	bool	typbyval;
	char	typalign;

	/* array of elements */
	char   *data;		/* nsorted items first, then unsorted ones */
} element_set_t;

/*
 * Initial size of the array (in bytes). This should be larger than the
 * minimum chunk size, which for AllocSet is 8B. As the element_set_t
 * struct has a fairly significant overhead (~40B) the 32B seems like a
 * reasonable value.
 */
#define ARRAY_INIT_SIZE		32

/* we want >= 20% free space after compaction (mostly arbitrary value) */
#define ARRAY_FREE_FRACT	0.2

/*
 * prototypes
 */

/* transition functions */
PG_FUNCTION_INFO_V1(count_distinct_append);
PG_FUNCTION_INFO_V1(count_distinct_elements_append);

/* parallel aggregation support functions */
PG_FUNCTION_INFO_V1(count_distinct_serial);
PG_FUNCTION_INFO_V1(count_distinct_deserial);
PG_FUNCTION_INFO_V1(count_distinct_combine);

/* final functions */
PG_FUNCTION_INFO_V1(count_distinct);
PG_FUNCTION_INFO_V1(array_agg_distinct_type_by_element);
PG_FUNCTION_INFO_V1(array_agg_distinct_type_by_array);

/* supplementary subroutines */
static void add_element(element_set_t *eset, char *value);
static element_set_t *init_set(int16 typlen, bool typbyval, char typalign, MemoryContext ctx);
static element_set_t *copy_set(element_set_t *eset);

static int compare_items(const void *a, const void *b, void *size);
static void compact_set(element_set_t *eset, bool need_space);
static Datum build_array(element_set_t *eset, Oid input_type);


Datum
count_distinct_append(PG_FUNCTION_ARGS)
{
	element_set_t  *eset;

	/* info for anyelement */
	Oid			element_type = get_fn_expr_argtype(fcinfo->flinfo, 1);
	Datum		element = PG_GETARG_DATUM(1);

	/* memory contexts */
	MemoryContext	oldcontext;
	MemoryContext	aggcontext;

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
		int16		typlen;
		bool		typbyval;
		char		typalign;

		/* get type information for the second parameter (anyelement item) */
		get_typlenbyvalalign(element_type, &typlen, &typbyval, &typalign);

		/* we can't handle varlena types yet or values passed by reference */
		if ((typlen < 0) || (! typbyval))
			elog(ERROR, "count_distinct handles only fixed-length types passed by value");

		eset = init_set(typlen, typbyval, typalign, aggcontext);
	} else
		eset = (element_set_t *) PG_GETARG_POINTER(0);

	/* add the value into the set */
	add_element(eset, (char *) &element);

	MemoryContextSwitchTo(oldcontext);

	PG_RETURN_POINTER(eset);
}

Datum
count_distinct_elements_append(PG_FUNCTION_ARGS)
{
	int				i;
	element_set_t  *eset = NULL;

	/* info for anyarray */
	Oid	input_type;
	Oid	element_type;

	/* array data */
	ArrayType  *input;
	Datum	   *elements;
	bool	   *nulls;
	int			nelements;

	/* needed for array deconstruction */
	int16		typlen;
	bool		typbyval;
	char		typalign;

	/* memory contexts */
	MemoryContext	oldcontext;
	MemoryContext	aggcontext;

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

	/* make sure we're running as part of aggregate function */
	GET_AGG_CONTEXT("count_distinct_elements_append", fcinfo, aggcontext);

	oldcontext = MemoryContextSwitchTo(aggcontext);

	/* get existing state, if any (otherwise leave it NULL) */
	if (!PG_ARGISNULL(0))
		eset = (element_set_t *) PG_GETARG_POINTER(0);

	/* parse the array contents (we know we got non-NULL value) */
	input = PG_GETARG_ARRAYTYPE_P(1);

	/*
	 * get type information for the second parameter (anyelement item), from
	 * the existing state or from cache.
	 */
	if (eset)
	{
		typlen = eset->typlen;
		typbyval = eset->typbyval;
		typalign = eset->typalign;
	}
	else
		get_typlenbyvalalign(element_type, &typlen, &typbyval, &typalign);

	/* we can't handle varlena types yet or values passed by reference */
	if ((typlen < 0) || (! typbyval))
		elog(ERROR, "count_distinct handles only fixed-length types passed by value");

	deconstruct_array(input,
					  element_type, typlen, typbyval, typalign,
					  &elements, &nulls, &nelements);

	/* add all non-NULL array elements to the set */
	for (i = 0; i < nelements; i++)
	{
		Datum	value;

		/* ignore nulls */
		if (nulls[i])
			continue;

		/* init the hash table, if needed */
		if (!eset)
			eset = init_set(typlen, typbyval, typalign, aggcontext);

		/*
		 * We need to copy just the significant bytes - we can't use memcpy
		 * directly, as that assumes little endian behavior.  store_att_byval
		 * does almost what we need, but it requires properly aligned buffer.
		 * We simply use a local Datum variable (which does guarante proper
		 * alignment), and then copy the value from it.
		 */
		store_att_byval(&value, elements[i], eset->typlen);

		add_element(eset, (char *) &value);
	}

	MemoryContextSwitchTo(oldcontext);

	/* free arrays allocated by deconstruct_array */
	pfree(elements);
	pfree(nulls);

	if (eset == NULL)
		PG_RETURN_NULL();

	PG_RETURN_POINTER(eset);
}

Datum
count_distinct_serial(PG_FUNCTION_ARGS)
{
	element_set_t *eset = (element_set_t *) PG_GETARG_POINTER(0);
	Size	hlen = offsetof(element_set_t, data);	/* header */
	Size	dlen;									/* elements */
	bytea  *out;									/* output */
	char   *ptr;

	Assert(eset != NULL);

	CHECK_AGG_CONTEXT("count_distinct_serial", fcinfo);

	/*
	 * force compaction, so that we serialize the smallest amount of data
	 * and also make sure the data is sorted (and the sort happens in the
	 * parallel workers, ot distribute the CPU better)
	 */
	compact_set(eset, false);

	Assert(eset->nall > 0);
	Assert(eset->nall == eset->nsorted);

	dlen = eset->nall * eset->typlen;

	out = (bytea *) palloc(VARHDRSZ + dlen + hlen);

	SET_VARSIZE(out, VARHDRSZ + dlen + hlen);
	ptr = VARDATA(out);

	memcpy(ptr, eset, hlen);
	ptr += hlen;

	memcpy(ptr, eset->data, dlen);

	PG_RETURN_BYTEA_P(out);
}

Datum
count_distinct_deserial(PG_FUNCTION_ARGS)
{
	element_set_t *eset = (element_set_t *) palloc(sizeof(element_set_t));
	bytea  *state = (bytea *) PG_GETARG_POINTER(0);
	Size	len PG_USED_FOR_ASSERTS_ONLY = VARSIZE_ANY_EXHDR(state);
	char   *ptr = VARDATA_ANY(state);

	CHECK_AGG_CONTEXT("count_distinct_deserial", fcinfo);

	Assert(len > 0);
	Assert((len - offsetof(element_set_t, data)) > 0);

	/* copy the header */
	memcpy(eset, ptr, offsetof(element_set_t, data));
	ptr += offsetof(element_set_t, data);

	Assert((eset->nall > 0) && (eset->nall == eset->nsorted));
	Assert(len == offsetof(element_set_t, data) + eset->nall * eset->typlen);

	/* we only allocate the necessary space */
	eset->data = palloc(eset->nall * eset->typlen);
	eset->nbytes = eset->nall * eset->typlen;

	memcpy((void *) eset->data, ptr, eset->nall * eset->typlen);

	PG_RETURN_POINTER(eset);
}

Datum
count_distinct_combine(PG_FUNCTION_ARGS)
{
	int				i;
	char		   *data,
				   *tmp,
				   *ptr1,
				   *ptr2,
				   *prev;
	element_set_t  *eset1;
	element_set_t  *eset2;
	MemoryContext	agg_context;
	MemoryContext	old_context;

	GET_AGG_CONTEXT("count_distinct_combine", fcinfo, agg_context);

	eset1 = PG_ARGISNULL(0) ? NULL : (element_set_t *) PG_GETARG_POINTER(0);
	eset2 = PG_ARGISNULL(1) ? NULL : (element_set_t *) PG_GETARG_POINTER(1);

	if (eset2 == NULL) {
		/* pass eset1 down the line */
		if (eset1 == NULL)
			PG_RETURN_NULL();
		else
			PG_RETURN_POINTER(eset1);
	}

	if (eset1 == NULL)
	{
		old_context = MemoryContextSwitchTo(agg_context);

		eset1 = copy_set(eset2);

		MemoryContextSwitchTo(old_context);

		PG_RETURN_POINTER(eset1);
	}

	Assert((eset1 != NULL) && (eset2 != NULL));
	Assert((eset1->typlen > 0) && (eset1->typlen == eset2->typlen));

	/* make sure both states are sorted */
	compact_set(eset1, false);
	compact_set(eset2, false);

	data = MemoryContextAlloc(agg_context, (eset1->nbytes + eset2->nbytes));
	tmp = data;

	/* merge the two arrays */
	ptr1 = eset1->data;
	ptr2 = eset2->data;
	prev = NULL;

	for (i = 0; i < eset1->nall + eset2->nall; i++)
	{
		char *element;

		Assert(ptr1 <= (eset1->data + eset1->nbytes));
		Assert(ptr2 <= (eset2->data + eset2->nbytes));

		if ((ptr1 < (eset1->data + eset1->nbytes)) &&
			(ptr2 < (eset2->data + eset2->nbytes)))
		{
			if (memcmp(ptr1, ptr2, eset1->typlen) <= 0)
			{
				element = ptr1;
				ptr1 += eset1->typlen;
			}
			else
			{
				element = ptr2;
				ptr2 += eset1->typlen;
			}
		}
		else if (ptr1 < (eset1->data + eset1->nbytes))
		{
			element = ptr1;
			ptr1 += eset1->typlen;
		}
		else if (ptr2 < (eset2->data + eset2->nbytes))
		{
			element = ptr2;
			ptr2 += eset2->typlen;
		}
		else
			elog(ERROR, "unexpected");

		/*
		 * Now figure out what to do with the element - we need to compare it
		 * to the last value, and only keep it if it's different (and it better
		 * be greater than the last value).
		 */
		if (tmp == data)
		{
			/* first value, so just copy */
			memcpy(tmp, element, eset1->typlen);
			prev = tmp;
			tmp += eset1->typlen;
		}
		else if (memcmp(prev, element, eset1->typlen) != 0)
		{
			/* not equal to the last one, so should be greater */
			Assert(memcmp(prev, element, eset1->typlen) < 0);

			/* first value, so just copy */
			memcpy(tmp, element, eset1->typlen);
			prev = tmp;
			tmp += eset1->typlen;
		}
	}

	/* we must have processed the input arrays completely */
	Assert(ptr1 == (eset1->data + (eset1->nall * eset1->typlen)));
	Assert(ptr2 == (eset2->data + (eset2->nall * eset2->typlen)));

	/* we might have eliminated some duplicate elements */
	Assert((tmp - data) <= ((eset1->nall + eset2->nall) * eset1->typlen));

	pfree(eset1->data);
	eset1->data = data;

	/* and finally compute the current number of elements */
	eset1->nbytes = tmp - data;
	eset1->nall = eset1->nbytes / eset1->typlen;
	eset1->nsorted = eset1->nall;

	PG_RETURN_POINTER(eset1);
}

Datum
count_distinct(PG_FUNCTION_ARGS)
{
	element_set_t  *eset;

	CHECK_AGG_CONTEXT("count_distinct", fcinfo);

	if (PG_ARGISNULL(0))
		PG_RETURN_NULL();

	eset = (element_set_t *) PG_GETARG_POINTER(0);

	/* do the compaction */
	compact_set(eset, false);

	PG_RETURN_INT64(eset->nall);
}

Datum
array_agg_distinct_type_by_element(PG_FUNCTION_ARGS)
{
	element_set_t  *eset;
	Oid				element_type;

	/* get element type for the dummy second parameter (anynonarray item) */
	eset = (element_set_t *) PG_GETARG_POINTER(0);
	element_type = get_fn_expr_argtype(fcinfo->flinfo, 1);

	CHECK_AGG_CONTEXT("count_distinct", fcinfo);

	/* return empty array if the state was not initialized */
	if (PG_ARGISNULL(0))
		PG_RETURN_DATUM(PointerGetDatum(construct_empty_array(element_type)));

	PG_RETURN_DATUM(build_array(eset, element_type));
}

Datum
array_agg_distinct_type_by_array(PG_FUNCTION_ARGS)
{
	element_set_t  *eset;
	Oid				input_type;
	Oid				element_type;

	/* get element type for the dummy second parameter (anyarray item) */
	eset = (element_set_t *) PG_GETARG_POINTER(0);
	input_type = get_fn_expr_argtype(fcinfo->flinfo, 1);
	element_type = get_element_type(input_type);

	CHECK_AGG_CONTEXT("count_distinct", fcinfo);

	/* return empty array if the state was not initialized */
	if (PG_ARGISNULL(0))
		PG_RETURN_DATUM(PointerGetDatum(construct_empty_array(element_type)));

	PG_RETURN_DATUM(build_array(eset, element_type));
}

static Datum
build_array(element_set_t *eset, Oid element_type)
{
	Datum		*array_of_datums;
	ArrayType   *array;
	int i;

	/* do the compaction */
	compact_set(eset, false);

	/*
	 * Copy data from compact array to array of Datums
	 * A bit suboptimal way, spends excessive memory.
	 */
	array_of_datums = palloc0(eset->nsorted * sizeof(Datum));
	for (i = 0; i < eset->nsorted; i++)
		memcpy(array_of_datums + i, eset->data + (eset->typlen * i), eset->typlen);

	/* build and return the array */
	array = construct_array(array_of_datums, eset->nsorted, element_type,
							eset->typlen, eset->typbyval, eset->typalign);

	/* free the array (not needed anymore) */
	pfree(array_of_datums);

	return PointerGetDatum(array);
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
compact_set(element_set_t *eset, bool need_space)
{
	char   *base = eset->data + (eset->nsorted * eset->typlen);
	char   *last = base;
	char   *curr;
	int		i;
	int		cnt = 1;
	double	free_fract;

	Assert(eset->nall > 0);
	Assert(eset->data != NULL);
	Assert(eset->nsorted <= eset->nall);
	Assert(eset->nall * eset->typlen <= eset->nbytes);

	/* if there are no new (unsorted) items, we don't need to sort */
	if (eset->nall > eset->nsorted)
	{
		/*
		 * sort the array with new items, but only when not already sorted
		 *
		 * TODO Consider replacing this insert-sort for small number of items
		 * (for <64 items it might be faster than qsort)
		 */
		qsort_arg(eset->data + eset->nsorted * eset->typlen,
				  eset->nall - eset->nsorted, eset->typlen,
				  compare_items, &eset->typlen);

		/*
		 * Remove duplicate values from the sorted array. That is - walk through
		 * the array, compare each item with the preceding one, and only keep it
		 * if they differ. We skip the first value, as it's always unique (there
		 * is no preceding value it might be equal to).
		 */
		for (i = 1; i < eset->nall - eset->nsorted; i++)
		{
			curr = base + (i * eset->typlen);

			/* items differ (keep the item) */
			if (memcmp(last, curr, eset->typlen) != 0)
			{
				last += eset->typlen;
				cnt  += 1;

				/* only copy if really needed */
				if (last != curr)
					memcpy(last, curr, eset->typlen);
			}
		}

		/* duplicities removed -> update the number of items in this part */
		eset->nall = eset->nsorted + cnt;

		/* If this is the first sorted part, we can just use it as the 'sorted' part. */
		if (eset->nsorted == 0)
			eset->nsorted = eset->nall;

		/*
		 * TODO Another optimization opportunity is that we don't really need to
		 *		merge the arrays, if we freed enough space by processing the new
		 *		items. We may postpone that until the last call (when finalizing
		 *		the aggregate). OTOH if that happens, it shouldn't be that
		 *		expensive to merge because the number of new items will be small
		 *		(as we've removed a enough duplicities). But we still need to
		 *		shuffle the data around, which wastes memory bandwidth.
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
			char * a_max = eset->data + eset->nsorted * eset->typlen;

			/* the new array */
			char * b = eset->data + (eset->nsorted * eset->typlen);
			char * b_max = eset->data + eset->nall * eset->typlen;

			MemoryContextSwitchTo(oldctx);

			/*
			 * TODO There's a possibility for optimization - if we get already
			 *		sorted items (e.g. because of a subplan), we can just copy the
			 *		arrays. The check is as simple as checking
			 *
			 *		(a_first > b_last) || (a_last < b_first).
			 *
			 *		OTOH this is probably very unlikely to happen in practice.
			 */

			while (true)
			{
				int r = memcmp(a, b, eset->typlen);

				/*
				 * If both values are the same, copy one of them into the result and increment
				 * both. Otherwise, increment only the smaller value.
				 */
				if (r == 0)
				{
					memcpy(ptr, a, eset->typlen);
					a += eset->typlen;
					b += eset->typlen;
				}
				else if (r < 0)
				{
					memcpy(ptr, a, eset->typlen);
					a += eset->typlen;
				}
				else
				{
					memcpy(ptr, b, eset->typlen);
					b += eset->typlen;
				}

				ptr += eset->typlen;

				/*
				 * If we reached the end of (at least) one of the arrays, copy all
				 * the remaining items and we're done.
				 */
				if ((a == a_max) || (b == b_max))
				{
					if (a != a_max)		 /* b ended -> copy rest of a */
					{
						memcpy(ptr, a, a_max - a);
						ptr += (a_max - a);
					}
					else if (b != b_max)	/* a ended -> copy rest of b */
					{
						memcpy(ptr, b, b_max - b);
						ptr += (b_max - b);
					}

					break;
				}
			}

			Assert((ptr - data) <= (eset->nall * eset->typlen));

			/*
			 * Update the counts with the result of the merge (there might be
			 * duplicities between the two parts, and we have eliminated them).
			 */
			eset->nsorted = (ptr - data) / eset->typlen;
			eset->nall = eset->nsorted;
			pfree(eset->data);
			eset->data = data;
		}
	}

	Assert(eset->nall == eset->nsorted);

	/* compute free space as a fraction of the total size */
	free_fract
		= (eset->nbytes - eset->nall * eset->typlen) * 1.0 / eset->nbytes;

	/*
	 * If we need space for more items (e.g. not when finalizing the aggregate
	 * result), enlarge the array when needed. We require ARRAY_FREE_FRACT of
	 * the space to be free.
	 */
	if (need_space && (free_fract < ARRAY_FREE_FRACT))
	{
		/*
		 * For small requests, we simply double the array size, because that's
		 * what AllocSet will give use anyway. No point in trying to save
		 * memory by growing the array slower.
		 *
		 * After reaching ALLOCSET_SEPARATE_THRESHOLD, the memory is allocated
		 * in separate blocks, thus we can be smarter and grow the memory
		 * a bit slower (just enough to get the 20% free space).
		 *
		 * XXX If the memory context uses smaller blocks, the switch to special
		 * blocks may happen before ALLOCSET_SEPARATE_THRESHOLD. This limit
		 * is simply global guarantee for all possible AllocSets.
		 */
		if ((eset->nbytes / 0.8) < ALLOCSET_SEPARATE_THRESHOLD)
			eset->nbytes *= 2;
		else
			eset->nbytes /= 0.8;

		eset->data = repalloc(eset->data, eset->nbytes);
	}

#if DEBUG_PROFILE
	elog(WARNING, "compact_set: bytes=%lu item=%d all=%d sorted=%d",
				  eset->nbytes, eset->typlen, eset->nall, eset->nsorted);
#endif
}

static void
add_element(element_set_t *eset, char *value)
{
	/*
	 * If there's not enough space for another item, perform compaction
	 * (this also allocates enough free space for new entries).
	 */
	if (eset->typlen * (eset->nall + 1) > eset->nbytes)
		compact_set(eset, true);

	/* there needs to be space for at least one more value (thanks to the compaction) */
	Assert(eset->nbytes >= eset->typlen * (eset->nall + 1));

	/* now we're sure there's enough space */
	memcpy(eset->data + (eset->typlen * eset->nall), value, eset->typlen);
	eset->nall += 1;
}

/* XXX make sure the whole method is called within the aggregate context */
static element_set_t *
init_set(int16 typlen, bool typbyval, char typalign, MemoryContext ctx)
{
	element_set_t * eset = (element_set_t *) palloc(sizeof(element_set_t));

	eset->typlen = typlen;
	eset->typbyval = typbyval;
	eset->typalign = typalign;
	eset->nsorted = 0;
	eset->nall = 0;
	eset->nbytes = ARRAY_INIT_SIZE;
	eset->aggctx = ctx;

	eset->data = palloc(eset->nbytes);

	return eset;
}

static element_set_t *
copy_set(element_set_t *eset)
{
	element_set_t *copy;

	copy = (element_set_t *) palloc(sizeof(element_set_t));
	copy->typlen = eset->typlen;
	copy->typalign = eset->typalign;
	copy->typbyval = eset->typbyval;
	copy->nsorted = eset->nsorted;
	copy->nall = eset->nall;
	copy->nbytes = eset->nbytes;

	copy->data = palloc(eset->nbytes);

	memcpy(copy->data, eset->data, eset->nbytes);

	return copy;
}

/* just compare the data directly using memcmp */
static int
compare_items(const void *a, const void *b, void *size)
{
	return memcmp(a, b, *(int *) size);
}
