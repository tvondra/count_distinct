/* count_distinct for int and bigint */

CREATE OR REPLACE FUNCTION count_distinct_append(p_pointer internal, p_element anyelement)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_append'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION count_distinct(p_pointer internal)
    RETURNS bigint
    AS 'count_distinct', 'count_distinct'
    LANGUAGE C IMMUTABLE;

CREATE AGGREGATE count_distinct(p_element anyelement) (
    SFUNC = count_distinct_append,
    STYPE = internal,
    FINALFUNC = count_distinct
);
