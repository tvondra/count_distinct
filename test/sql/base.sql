\set ECHO none
BEGIN;

\i sql/count_distinct--2.0.1.sql

\set ECHO all

-- int
SELECT count_distinct(x::int) FROM generate_series(1,1000) s(x);
SELECT count_distinct(mod(x,10)::int) FROM generate_series(1,1000) s(x);
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(x::int)) a FROM generate_series(1,1000) s(x))_;
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(mod(x,10)::int)) a FROM generate_series(1,1000) s(x))_;
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(array[x::int, x::int, -x::int])) a FROM generate_series(1,1000) s(x))_;
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(array[mod(x,10)::int, mod(x,10)::int, -mod(x,10)::int])) a FROM generate_series(1,1000) s(x))_;

-- bigint
SELECT count_distinct(x::bigint) FROM generate_series(1,1000) s(x);
SELECT count_distinct(mod(x,10)::bigint) FROM generate_series(1,1000) s(x);
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(x::bigint)) a FROM generate_series(1,1000) s(x))_;
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(mod(x,10)::bigint)) a FROM generate_series(1,1000) s(x))_;
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(array[x::bigint, x::bigint, -x::bigint])) a FROM generate_series(1,1000) s(x))_;
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(array[mod(x,10)::bigint, mod(x,10)::bigint, -mod(x,10)::bigint])) a FROM generate_series(1,1000) s(x))_;

-- timestamp
select count_distinct('epoch'::timestamp + (x || ' days')::interval) from generate_series(1,1000) s(x);
select count_distinct('epoch'::timestamptz+ (x || ' days')::interval) from generate_series(1,1000) s(x);
SELECT array_agg(a - 'epoch'::timestamp order by a) FROM (SELECT unnest(array_agg_distinct('epoch'::timestamp + (x || ' days')::interval)) a FROM generate_series(1,1000) s(x))_;
SELECT array_agg(a - 'epoch'::timestamptz order by a) FROM (SELECT unnest(array_agg_distinct('epoch'::timestamptz+ (x || ' days')::interval)) a FROM generate_series(1,1000) s(x))_;
SELECT array_agg(a - 'epoch'::timestamp order by a) FROM (SELECT unnest(array_agg_distinct(array['epoch'::timestamp + (x || ' days')::interval, 'epoch'::timestamp + (x || ' days')::interval, 'epoch'::timestamp - (x || ' days')::interval])) a FROM generate_series(1,1000) s(x))_;
SELECT array_agg(a - 'epoch'::timestamptz at time zone 'GMT' order by a) FROM (SELECT unnest(array_agg_distinct(array['epoch'::timestamptz+ (x || ' days')::interval, 'epoch'::timestamptz+ (x || ' days')::interval, 'epoch'::timestamptz- (x || ' days')::interval])) a FROM generate_series(1,1000) s(x))_;

-- bool
select count_distinct(x::bool) from generate_series(0,1000) s(x);
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(x::bool)) a FROM generate_series(1,1000) s(x))_;
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(array[null, x::bool, x::bool, not x::bool])) a FROM generate_series(1,1000) s(x))_;

-- int2
select count_distinct(x::int2) from generate_series(1,1000) s(x);
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(x::int2)) a FROM generate_series(1,1000) s(x))_;
SELECT array_agg(a order by a) FROM (SELECT unnest(array_agg_distinct(array[x::int2, x::int2, -x::int2])) a FROM generate_series(1,1000) s(x))_;

ROLLBACK;
