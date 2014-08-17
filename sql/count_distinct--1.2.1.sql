/* count_distinct for int and bigint */

CREATE OR REPLACE FUNCTION count_distinct_append(internal, anyelement)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_append'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION count_distinct(internal)
    RETURNS bigint
    AS 'count_distinct', 'count_distinct'
    LANGUAGE C IMMUTABLE;

CREATE AGGREGATE count_distinct(anyelement) (
    SFUNC = count_distinct_append,
    STYPE = internal,
    FINALFUNC = count_distinct
);
