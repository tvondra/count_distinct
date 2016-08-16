\set ECHO none
BEGIN;

\i sql/count_distinct--1.3.2.sql

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

-- array of int
SELECT count_distinct_elements(z) FROM (
    SELECT ARRAY[x::int, (x+1)::int] AS z FROM generate_series(1,1000) s(x)
) foo;

SELECT count_distinct_elements(z) FROM (
    SELECT ARRAY[mod(x,10)::int, mod(x+1,10)::int] AS z FROM generate_series(1,1000) s(x)
) foo;

-- array of bigint
SELECT count_distinct_elements(z) FROM (
    SELECT ARRAY[x::bigint, (x+1)::bigint] AS z FROM generate_series(1,1000) s(x)
) foo;

SELECT count_distinct_elements(z) FROM (
    SELECT ARRAY[mod(x,10)::bigint, mod(x+1,10)::bigint] AS z FROM generate_series(1,1000) s(x)
) foo;

-- array of timestamp
SELECT count_distinct_elements(z) FROM (
    SELECT ARRAY[now()::timestamp + (x || ' days')::interval,
                 now()::timestamp + ((x + 1) || ' days')::interval] AS z
    FROM generate_series(1,1000) s(x)
) foo;

SELECT count_distinct_elements(z) FROM (
    SELECT ARRAY[now() + (x || ' days')::interval,
                 now() + ((x + 1) || ' days')::interval] AS z
    FROM generate_series(1,1000) s(x)
) foo;

-- array of bool
SELECT count_distinct_elements(z) FROM (
    SELECT ARRAY[x::bool, (x+1)::bool] AS z FROM generate_series(1,1000) s(x)
) foo;

SELECT count_distinct_elements(z) FROM (
    SELECT ARRAY[mod(x,10)::bool, mod(x+1,10)::bool] AS z FROM generate_series(1,1000) s(x)
) foo;

-- array of int2 with nulls
SELECT count_distinct_elements(z) FROM (
    SELECT ARRAY[NULL, x::int2, NULL, NULL, (x+1)::int2, NULL] AS z FROM generate_series(1,1000) s(x)
) foo;

SELECT count_distinct_elements(z) FROM (
    SELECT ARRAY[mod(x,10)::int2, mod(x+1,10)::int2] AS z FROM generate_series(1,1000) s(x)
) foo;

ROLLBACK;
