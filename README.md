COUNT_DISTINCT aggregate
========================
This extension provides a hash-based alternative to COUNT(DISTINCT ...)
which usually ends in sorting and bad performance.

Functions
---------
There are two aggregate functions - for INT and BIGINT respectively.

* count_distinct(p_value int)
* count_distinct(p_value bigint)

Extending the same approach to other data types should be rather
straight-forward (but it's important to be very careful about memory
consumption, as the hash-based approach keeps everything in RAM).


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

    $ psql dbname < `pg_config --sharedir`/contrib/count_distinct--1.0.0.sql

That's all.


License
-------
This software is distributed under the terms of BSD 2-clause license.
See LICENSE or http://www.opensource.org/licenses/bsd-license.php for
more details.
