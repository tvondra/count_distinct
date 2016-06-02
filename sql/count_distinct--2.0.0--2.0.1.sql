DROP AGGREGATE array_agg_distinct(anyelement);

DROP FUNCTION array_agg_distinct(internal, anyelement);

CREATE OR REPLACE FUNCTION array_agg_distinct(internal, anynonarray)
    RETURNS anyarray
    AS 'count_distinct', 'array_agg_distinct'
    LANGUAGE C IMMUTABLE;

CREATE AGGREGATE array_agg_distinct(anynonarray) (
    SFUNC = count_distinct_append,
    STYPE = internal,
    FINALFUNC = array_agg_distinct,
    finalfunc_extra
);
