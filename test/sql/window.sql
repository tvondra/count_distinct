\set ECHO none
BEGIN;

\i sql/count_distinct--1.3.3.sql

\set ECHO all

select count_distinct(a) over (order by a rows between unbounded preceding and current row)
  from generate_series(1, 20) a;

-- This test will fail on postgres 8.4, as this syntax is not supported
select count_distinct(a) over (order by a rows between 10 preceding and 10 following)
  from generate_series(1, 25) a;

ROLLBACK;
