COUNT_DISTINCT aggregate
========================
This extension provides a hashAgg-compatible alternative to 
COUNT(DISTINCT ...) and ARRAY_AGG(DISTINCT ...)
which for large amounts of data often end in sorting and bad performance.

Functions
---------
There are three polymorphic aggregate functions, handling all fixed length
data types passed by value (i.e. up to 8B values on 64-bit machines) 
or arrays of such types:

* count_distinct(anyelement)
* array_agg_distinct(anynonarray)
* array_agg_distinct(anyarray)

Extending the same approach to other data types (varlena or passed by
reference) should be rather straight-forward and I'll do that eventually.
But it's important to be very careful about memory consumption, as the
hash-based approach keeps everything in RAM).

If arrays are passed as input values, the `count_distinct` function computes
the number of distinct elements in the union of those arrays. Similarly,
`array_agg_distinct` aggregates distinct elements of input arrays
into a one-dimensional array.

All input NULLs are ignored.

Performance
-----------
So, what's wrong with plain COUNT(DISTINCT ...). Let's use this table
for some tests

    CREATE TABLE test_table (id INT, val INT);
    
    INSERT INTO test_table
         SELECT mod(i, 1000), (1000 * random())::int
           FROM generate_series(1,10000000) s(i);
    
    ANALYZE test_table;
    
Now, let's try this query

    SELECT id, COUNT(DISTINCT val) FROM test_table GROUP BY 1
    
which is executed like this

    GroupAggregate  (cost=1443649.74..1518660.10 rows=1000 width=8)
      ->  Sort  (cost=1443649.74..1468649.86 rows=10000048 width=8)
            Sort Key: id
            ->  Seq Scan on test_table  (cost=0.00..144248.48 rows=...
    (4 rows)

On my machine, it takes between 11.5 and 12 seconds, no matter what, and 
about ~90% of the time is spent on the sort. So let's see if we can do
that without the sort faster using the COUNT_DISTINCT() aggregate:

    SELECT id, COUNT_DISTINCT(val) FROM test_table GROUP BY 1

which results in an explain plan like this:
    
    HashAggregate  (cost=194248.72..194261.22 rows=1000 width=8)
      ->  Seq Scan on test_table  (cost=0.00..144248.48 rows=10000048 ...
    (2 rows)

This aggregate function takes ~4.1 seconds and produces exactly the same
results (but unsorted).


Issues
------
The current implementation works only with fixed-length values passed by
value (i.e. limited by the pointer size), but it should be rather simple
to extend this to other data types. One way to overcome this limitation
is hashing the value into a 32/64-bit integers, and then passing these
hash values to count_distinct (see https://github.com/tvondra/pghashlib
for a good library of hash functions). However be careful as this
effectively turns `count_distinct` into an estimator.

If an estimator is sufficient for you, maybe
[postgresql-hll](https://github.com/aggregateknowledge/postgresql-hll)
or one of the estimators at [distinct_estimators](https://github.com/tvondra/distinct_estimators)
would be a better solution for you?


With the previous implementation (based on hash tables), memory consumption
was a big problem. For example when counting 80M unique 32-bit integers,
it was common to see more than 5GB of RAM allocated (which is way more than
the 320MB necessary for the values, and ~1.6GB when including some hash
table related overhead (buckets, pointers, ...). This was mostly due to
clashing with MemoryContext internals, etc.

With the new implementation significantly improves this, and the memory
consumption is a fraction (usually less than 10-20% of what it used to be).


Still, it may happen that you run out of memory. It's not very likely
because for large number of groups planner will switch to GroupAggregate
(effectively keeping a single group in memory), but it's possible.

Sadly, that is not something the extension could handle internally in
a reasonable way. The only actual solution is to implement this into
HashAggregate itself (some people are working on this, but don't hold
your breath - it won't happen before 9.5).

So in short - if you're dealing with a lot of distinct values, you need
a lot of RAM in the machine.


Installation
------------
Installing this is very simple, especially if you're using pgxn client.
All you need to do is this:

    $ pgxn install count_distinct
    $ pgxn load -d mydb count_distinct

and you're done. You may also install the extension manually:

    $ make install
    $ psql dbname -c "CREATE EXTENSION count_distinct"

That's all.


License
-------
This software is distributed under the terms of BSD 2-clause license.
See LICENSE or http://www.opensource.org/licenses/bsd-license.php for
more details.
