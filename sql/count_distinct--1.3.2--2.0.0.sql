CREATE OR REPLACE FUNCTION array_agg_distinct(internal, anyelement)
    RETURNS anyarray
    AS 'count_distinct', 'array_agg_distinct'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION array_agg_distinct(internal, anyarray)
    RETURNS anyarray
    AS 'count_distinct', 'array_agg_distinct'
    LANGUAGE C IMMUTABLE;

CREATE AGGREGATE array_agg_distinct(anyelement) (
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
