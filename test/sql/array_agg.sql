\set ECHO none
\i test/sql/setup/setup.sql

-- int
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(x::int)) a FROM test_data_1_50)_;
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(mod(x,10)::int)) a FROM test_data_1_50)_;

-- bigint
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(x::bigint)) a FROM test_data_1_50)_;
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(mod(x,10)::bigint)) a FROM test_data_1_50)_;

-- timestamp
SELECT unnest(array_agg(a order by a)) FROM (SELECT unnest(array_agg_distinct('epoch'::timestamp + (x || ' days')::interval)) a FROM test_data_1_50)_;
SELECT unnest(array_agg(a order by a)) FROM (SELECT unnest(array_agg_distinct('epoch'::timestamptz + (x || ' days')::interval)) a FROM test_data_1_50)_;

-- bool
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(mod(x,2)::bool)) a FROM test_data_1_50)_;

-- bool w/nulls
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(nullif(mod(x,2), 0)::bool)) a FROM test_data_0_50)_;

-- int2
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(x::int2)) a FROM test_data_1_50)_;

ROLLBACK;
