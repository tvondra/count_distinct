/* drop aggregate functions */
DROP AGGREGATE count_distinct(anyelement);
DROP AGGREGATE array_agg_distinct(anynonarray);
DROP AGGREGATE count_distinct_elements(anyarray);
DROP AGGREGATE array_agg_distinct_elements(anyarray);

/* create parallel aggregation support functions */
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

/* rereate the aggregate functions */
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
