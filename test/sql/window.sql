\set ECHO none
BEGIN;

\i sql/count_distinct--2.0.0.sql

\set ECHO all

select count_distinct(a) over (order by a rows between unbounded preceding and current row)
  from generate_series(1, 20) a;

select count_distinct(a) over (order by a rows between 10 preceding and 10 following)
  from generate_series(1, 25) a;

ROLLBACK;
