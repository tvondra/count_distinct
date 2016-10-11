\set ECHO none
\i test/sql/setup/setup.sql

-- int
SELECT count_distinct(x::int) FROM test_data_1_1000;
SELECT count_distinct(mod(x,10)::int) FROM test_data_1_1000;

-- bigint
SELECT count_distinct(x::bigint) FROM test_data_1_1000;
SELECT count_distinct(mod(x,10)::bigint) FROM test_data_1_1000;

-- timestamp
select count_distinct(now()::timestamp + (x || ' days')::interval) from test_data_1_1000;
select count_distinct(now() + (x || ' days')::interval) from test_data_1_1000;

-- bool
select count_distinct(x::bool) from test_data_0_1000;

-- int2
select count_distinct(x::int2) from test_data_1_1000;

ROLLBACK;
