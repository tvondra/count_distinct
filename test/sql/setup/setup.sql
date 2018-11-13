\set ECHO none

BEGIN;

-- install the module
\i sql/count_distinct--3.0.0.sql

-- create and analyze tables (parallel plans work only on real tables, not on SRFs)
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

-- force parallel execution and check if it works
do $$
declare
    t text;
    cfg text = case when current_setting('server_version_num')::int >= 100000 then 'min_parallel_table_scan_size' else 'min_parallel_relation_size' end;
begin
    perform set_config(cfg, '0', true),
            set_config('parallel_setup_cost', '0', true),
            set_config('parallel_tuple_cost', '0', true),
            set_config('max_parallel_workers_per_gather', '22', true);

    for t in explain select count(*) from test_data_1_20 loop
        if t like '%Gather%' then
            -- Here we can see parallel execution is on
            return;
        end if;
    end loop;
    raise 'Looks like parallel aggregation is off';
end;
$$;

\set ECHO all
