\set ECHO none
\i test/sql/setup/setup.sql

select count_distinct(x) over (order by x rows between unbounded preceding and current row)
  from test_data_1_20;

select count_distinct(x) over (order by x rows between 10 preceding and 10 following)
  from test_data_1_25;

ROLLBACK;
