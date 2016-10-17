\set ECHO none

BEGIN;

-- install the module
\i sql/count_distinct--2.0.0.sql

-- create and analyze tables
create table test_data_1_20 as select generate_series(1,20) x;
create table test_data_1_25 as select generate_series(1,25) x;
create table test_data_0_50 as select generate_series(0,50) x;
create table test_data_1_50 as select generate_series(1,50) x;
create table test_data_1_1000 as select generate_series(1,1000) x;
create table test_data_0_1000 as select generate_series(0,1000) x;
analyze test_data_1_20;
analyze test_data_1_25;
analyze test_data_0_50;
analyze test_data_1_50;
analyze test_data_1_1000;
analyze test_data_0_1000;

\set ECHO all
