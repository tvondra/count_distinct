/* count_distinct for int and bigint */

CREATE OR REPLACE FUNCTION count_distinct_append(internal, anyelement)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_append'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION count_distinct_elements_append(internal, anyarray)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_elements_append'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION count_distinct(internal)
    RETURNS bigint
    AS 'count_distinct', 'count_distinct'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION array_agg_distinct(internal, anynonarray)
    RETURNS anyarray
    AS 'count_distinct', 'array_agg_distinct_type_by_element'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION array_agg_distinct(internal, anyarray)
    RETURNS anyarray
    AS 'count_distinct', 'array_agg_distinct_type_by_array'
    LANGUAGE C IMMUTABLE;

/* Server supports parallel aggregation (9.6+) */

/* serialize data */
CREATE OR REPLACE FUNCTION count_distinct_serial(p_pointer internal)
    RETURNS bytea
    AS 'count_distinct', 'count_distinct_serial'
    LANGUAGE C IMMUTABLE STRICT;

/* deserialize data */
CREATE OR REPLACE FUNCTION count_distinct_deserial(p_value bytea, p_dummy internal)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_deserial'
    LANGUAGE C IMMUTABLE STRICT;

/* combine data */
CREATE OR REPLACE FUNCTION count_distinct_combine(p_state_1 internal, p_state_2 internal)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_combine'
    LANGUAGE C IMMUTABLE;

/* Create the aggregate functions */
CREATE AGGREGATE count_distinct(anyelement) (
       SFUNC = count_distinct_append,
       STYPE = internal,
       FINALFUNC = count_distinct,
       COMBINEFUNC = count_distinct_combine,
       SERIALFUNC = count_distinct_serial,
       DESERIALFUNC = count_distinct_deserial,
       PARALLEL = SAFE
);

CREATE AGGREGATE array_agg_distinct(anynonarray) (
       SFUNC = count_distinct_append,
       STYPE = internal,
       FINALFUNC = array_agg_distinct,
       FINALFUNC_EXTRA,
       COMBINEFUNC = count_distinct_combine,
       SERIALFUNC = count_distinct_serial,
       DESERIALFUNC = count_distinct_deserial,
       PARALLEL = SAFE
);

CREATE AGGREGATE count_distinct_elements(anyarray) (
       SFUNC = count_distinct_elements_append,
       STYPE = internal,
       FINALFUNC = count_distinct,
       COMBINEFUNC = count_distinct_combine,
       SERIALFUNC = count_distinct_serial,
       DESERIALFUNC = count_distinct_deserial,
       PARALLEL = SAFE
);

CREATE AGGREGATE array_agg_distinct_elements(anyarray) (
       SFUNC = count_distinct_elements_append,
       STYPE = internal,
       FINALFUNC = array_agg_distinct,
       FINALFUNC_EXTRA,
       COMBINEFUNC = count_distinct_combine,
       SERIALFUNC = count_distinct_serial,
       DESERIALFUNC = count_distinct_deserial,
       PARALLEL = SAFE
);
