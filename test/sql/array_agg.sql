\set ECHO none
BEGIN;

\i sql/count_distinct--2.0.0.sql

\set ECHO all

-- int
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(x::int)) a FROM generate_series(1,50) s(x))_;
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(mod(x,10)::int)) a FROM generate_series(1,50) s(x))_;

-- bigint
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(x::bigint)) a FROM generate_series(1,50) s(x))_;
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(mod(x,10)::bigint)) a FROM generate_series(1,50) s(x))_;

-- timestamp
SELECT unnest(array_agg(a order by a)) FROM (SELECT unnest(array_agg_distinct('epoch'::timestamp + (x || ' days')::interval)) a FROM generate_series(1,50) s(x))_;
SELECT unnest(array_agg(a order by a)) FROM (SELECT unnest(array_agg_distinct('epoch'::timestamptz + (x || ' days')::interval)) a FROM generate_series(1,50) s(x))_;

-- bool
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(mod(x,2)::bool)) a FROM generate_series(1,50) s(x))_;

-- bool w/nulls
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(nullif(mod(x,2), 0)::bool)) a FROM generate_series(0,50) s(x))_;

-- int2
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(x::int2)) a FROM generate_series(1,50) s(x))_;

ROLLBACK;
