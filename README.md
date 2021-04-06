COUNT_DISTINCT aggregate
========================
This extension provides an alternative to COUNT(DISTINCT ...) which for large
amounts of data often ends in sorting and poor performance.


Functions
---------
There are two polymorphic aggregate functions, handling fixed length
data types passed by value (i.e. up to 8B values on 64-bit machines):

* `count_distinct(p_value anyelement)`
* `array_agg_distinct(p_value anyelement)`

Two more functions accept arrays of the same types:

* `count_distinct_elements(p_value anyarray)`
* `array_agg_distinct_elements(p_value anyarray)`

and work with the elements of the input array (instead of the array
value itself).

Extending this approach to other data types (passed by reference) shoul
be rather straight-forward. But it's important to be very careful about
memory consumption, as the approach keeps everything in RAM. This issue
is discussed in more detail in one of the following sections.

Performance
-----------
So, what's wrong with plain `COUNT(DISTINCT ...)`? Let's use this table
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


Should I use this extension?
----------------------------
Answering this question is not entirely easy, and you need to consider a
couple of things:

* Do you need just `COUNT(DISTINCT ...)` or also `array_agg_distinct()`?

  If you only care about `COUNT(DISTINCT ...)`, then using the built-in
  stuff from PostgreSQL is an option, and you need to look at the rest
  of this section. If you need the `array_agg_distinct()` part, then
  using this extension is probably the right thing to do irrespective
  of the other questions.

* How much data are you dealing with?

  If you're only dealing with small amounts of data (a couple megabytes
  per group, or so), this extension is unlikely to be much faster than
  the built-in `COUNT(DISTINCT ...)` and may actually be slower.

* What is the data distribution?

  The main metric you need to look at is number of distinct values vs.
  number of rows in a group. The higher this value is, the less likely
  this extension will be a win, compared to `COUNT(DISTINCT ...)`. But
  if there's a lot of redundancy, the deduplication can save a lot.

* How serious is the OOM risk?

  There's no reasonable way to enforce `work_mem` for user aggregates,
  both during planning and execution. Depending on the aggregate method
  picked by planner (sort vs. hash) we may end up keeping all data or
  the current group in memory. For data sets with many groups and/or
  large number of distinct values in a group, this may end up by OOM.

  You need to judge how serious the OOM risk is, considering your data
  set, memory available on the system and workload characteristics (how
  many queries are running concurrently, etc.).

* Which PostgreSQL release are you using?

  On older PostgreSQL releases (9.x) this extension was almost always a
  clear win, compared to `COUNT(DISTINCT ...)`. But the performance got
  much better over time, so if you're using a reasonably recent release
  (say, 11+), then maybe just try using PostgreSQL. The speed is likely
  on par with this extension and handles memory consumption better.

  The one remaining advantage is support for parallel aggregation, which
  the built-in `COUNT(DISTINCT )` code does not support and it may block
  parallel aggregation for other aggregates in the same query.

Ultimately, the best thing you can do is do some testing ...


Benchmark
---------
The `benchmark` directory contains a couple of very simple benchmarking
scripts. The script `create-tables.sql` creates tables of different size
that are then used by queries in `bench-native.sql` (which is running
`COUNT(DISTINCT ...)`) and `bench-count-distinct.sql` (this extension).

An example of results from one particular machine (CPU Intel i5-2500k,
8GB RAM, SSD) on PostgreSQL 12 is in the following table.

    | scale  | query | native | serial | parallel | serial | parallel |
    |--------|-------|--------|--------|----------|--------|----------|
    | small  |     1 |     10 |     27 |       27 |   272% |     272% |
    |        |     2 |     10 |     27 |       27 |   270% |     270% |
    |        |     3 |     44 |     33 |       33 |    75% |      75% |
    |        |     4 |     93 |     60 |       61 |    65% |      66% |
    |        |     5 |     45 |     29 |       29 |    64% |      64% |
    |        |     6 |     93 |     60 |       61 |    65% |      66% |
    |        |     7 |     50 |     47 |       48 |    94% |      95% |
    |        |     8 |     93 |     60 |       61 |    65% |      65% |
    |        |     9 |     99 |     65 |       66 |    67% |      67% |
    |        |    10 |     93 |     60 |       61 |    65% |      65% |
    |        |    11 |     47 |     49 |       49 |   105% |     105% |
    |        |    12 |     90 |     68 |       68 |    76% |      76% |
    |        |    13 |     44 |     46 |       46 |   104% |     104% |
    |        |    14 |     47 |     49 |       49 |   105% |     105% |
    |        |    15 |     39 |     27 |       27 |    68% |      69% |
    |        |    16 |     79 |     58 |       58 |    73% |      74% |
    |--------|-------|--------|--------|----------|--------|----------|
    | medium |     1 |   2378 |   3602 |     1341 |   151% |      56% |
    |        |     2 |   2401 |   3630 |     1325 |   151% |      55% |
    |        |     3 |   6557 |   4045 |     1524 |    62% |      23% |
    |        |     4 |  10522 |   7206 |     7406 |    68% |      70% |
    |        |     5 |   6047 |   3827 |     1456 |    63% |      24% |
    |        |     6 |  10523 |   7232 |     7362 |    69% |      70% |
    |        |     7 |   5995 |   6482 |     1832 |   108% |      31% |
    |        |     8 |  10522 |   7246 |     7369 |    69% |      70% |
    |        |     9 |  11074 |   7759 |     7761 |    70% |      70% |
    |        |    10 |  10515 |   7212 |     7281 |    69% |      69% |
    |        |    11 |   6359 |   6997 |     1963 |   110% |      31% |
    |        |    12 |  10838 |   8675 |     8661 |    80% |      80% |
    |        |    13 |   5535 |   5692 |     1459 |   103% |      26% |
    |        |    14 |   6346 |   6993 |     2020 |   110% |      32% |
    |        |    15 |   5103 |   5455 |     1446 |   107% |      28% |
    |        |    16 |   9111 |   6960 |     6975 |    76% |      77% |
    |--------|-------|--------|--------|----------|--------|----------|
    | large  |     1 |  33655 |  38990 |    16370 |   116% |      49% |
    |        |     2 |  33733 |  39244 |    16341 |   116% |      48% |
    |        |     3 |  85952 |  45148 |    17881 |    53% |      21% |
    |        |     4 | 118266 |  85194 |    56260 |    72% |      48% |
    |        |     5 |  81632 |  42123 |    16852 |    52% |      21% |
    |        |     6 | 118185 |  84921 |    55843 |    72% |      47% |
    |        |     7 |  76657 |  83903 |    22802 |   109% |      30% |
    |        |     8 | 118012 |  85217 |    55288 |    72% |      47% |
    |        |     9 | 124608 |  91788 |    56302 |    74% |      45% |
    |        |    10 | 118311 |  85219 |    55101 |    72% |      47% |
    |        |    11 |  83338 |  88766 |    28569 |   107% |      34% |
    |        |    12 | 124434 | 102602 |    60438 |    82% |      49% |
    |        |    13 |  71783 |  70960 |    16877 |    99% |      24% |
    |        |    14 |  82105 |  87466 |    27524 |   107% |      34% |
    |        |    15 |  63803 |  67240 |    17426 |   105% |      27% |
    |        |    16 | 103516 |  82305 |    47196 |    80% |      46% |

The scale specifies how large the table is - 100k, 1M or 10M rows. There
are 16 different queries. The following three columns show timing (in
miliseconds), median of 6 runs. `native` means `COUNT(DISTINCT ...)`,
while `serial` and `parallel` means functions from this extention, with
parallel queries disabled and enabled. The last two columns are simply
timing compared to `native`.

It's clear that in serial mode `count_distinct` does perform roughly the
same as `COUNT(DISTINCT ...)` - sometimes it's 2x fast, sometimes a bit
slower than `native`. The `parallel` case however shows significant and
consistent improvements.


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

Versions
--------
* 1.3.x (branch REL1_3_STABLE) is legacy and supports PostgreSQL 8.4+,
only `count_distinct` aggregate function is provided.
* 2.0.x (branch REL2_0_STABLE) works on PostgreSQL 9.4+ and, in addition to `count_distinct`,
provides the following aggregate functions:
    * `count_distinct_elements` (for counting distinct elements in arrays)
    * `array_agg_distinct` (for aggregating distinct elements into an array)
    * `array_agg_distinct_elements` (for aggregating distinct elements of arrays into a single array)
* 3.0.x (master) requires PostgreSQL 9.6+ and supports parallel aggregation.

Installation
------------
Installing this is very simple, especially if you're using pgxn client.
All you need to do is this:

    $ pgxn install count_distinct
    $ pgxn load -d mydb count_distinct

and you're done. You may also install the extension manually:

    $ make install
    $ psql dbname -c "CREATE EXTENSION count_distinct"

And if you're on an older version (pre-9.1), you have to run the SQL
script manually

    $ psql dbname < `pg_config --sharedir`/contrib/count_distinct--2.0.0.sql

That's all.


License
-------
This software is distributed under the terms of BSD 2-clause license.
See LICENSE or http://www.opensource.org/licenses/bsd-license.php for
more details.
