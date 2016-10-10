\set ECHO none
BEGIN;

\i sql/count_distinct--1.3.3.sql

\set ECHO all

-- int
SELECT count_distinct(x::int) FROM generate_series(1,1000) s(x);
SELECT count_distinct(mod(x,10)::int) FROM generate_series(1,1000) s(x);

-- bigint
SELECT count_distinct(x::bigint) FROM generate_series(1,1000) s(x);
SELECT count_distinct(mod(x,10)::bigint) FROM generate_series(1,1000) s(x);

-- timestamp
select count_distinct(now()::timestamp + (x || ' days')::interval) from generate_series(1,1000) s(x);
select count_distinct(now() + (x || ' days')::interval) from generate_series(1,1000) s(x);

-- bool
select count_distinct(x::bool) from generate_series(0,1000) s(x);

-- int2
select count_distinct(x::int2) from generate_series(1,1000) s(x);

ROLLBACK;
