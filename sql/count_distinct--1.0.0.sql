/* count_distinct for int and bigint */

CREATE OR REPLACE FUNCTION count_distinct_append_int(p_pointer internal, p_element int)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_append_int32'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION count_distinct_append_int(p_pointer internal, p_element bigint)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_append_int64'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION count_distinct(p_pointer internal)
    RETURNS bigint
    AS 'count_distinct', 'count_distinct'
    LANGUAGE C IMMUTABLE;

CREATE AGGREGATE count_distinct(int) (
    SFUNC = count_distinct_append_int,
    STYPE = internal,
    FINALFUNC = count_distinct
);

CREATE AGGREGATE count_distinct(bigint) (
    SFUNC = count_distinct_append_int,
    STYPE = internal,
    FINALFUNC = count_distinct
);
