CREATE OR REPLACE FUNCTION count_distinct_elements_append(internal, anyarray)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_elements_append'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION array_agg_distinct(internal, anynonarray)
    RETURNS anyarray
    AS 'count_distinct', 'array_agg_distinct_type_by_element'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION array_agg_distinct(internal, anyarray)
    RETURNS anyarray
    AS 'count_distinct', 'array_agg_distinct_type_by_array'
    LANGUAGE C IMMUTABLE;

/* Create the aggregate function */
CREATE AGGREGATE array_agg_distinct(anynonarray) (
       SFUNC = count_distinct_append,
       STYPE = internal,
       FINALFUNC = array_agg_distinct,
       FINALFUNC_EXTRA
);

CREATE AGGREGATE count_distinct_elements(anyarray) (
       SFUNC = count_distinct_elements_append,
       STYPE = internal,
       FINALFUNC = count_distinct
);

CREATE AGGREGATE array_agg_distinct_elements(anyarray) (
       SFUNC = count_distinct_elements_append,
       STYPE = internal,
       FINALFUNC = array_agg_distinct,
       FINALFUNC_EXTRA
);
