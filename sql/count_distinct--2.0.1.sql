CREATE OR REPLACE FUNCTION count_distinct_append(internal, anyelement)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_append'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION count_distinct(internal)
    RETURNS bigint
    AS 'count_distinct', 'count_distinct'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION array_agg_distinct(internal, anynonarray)
    RETURNS anyarray
    AS 'count_distinct', 'array_agg_distinct'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION array_agg_distinct(internal, anyarray)
    RETURNS anyarray
    AS 'count_distinct', 'array_agg_distinct'
    LANGUAGE C IMMUTABLE;

CREATE AGGREGATE count_distinct(anyelement) (
    SFUNC = count_distinct_append,
    STYPE = internal,
    FINALFUNC = count_distinct
);

CREATE AGGREGATE array_agg_distinct(anynonarray) (
    SFUNC = count_distinct_append,
    STYPE = internal,
    FINALFUNC = array_agg_distinct,
    finalfunc_extra
);

CREATE AGGREGATE array_agg_distinct(anyarray) (
    SFUNC = count_distinct_append,
    STYPE = internal,
    FINALFUNC = array_agg_distinct,
    finalfunc_extra
);
