/* count_distinct for int and bigint */

CREATE OR REPLACE FUNCTION count_distinct_append(internal, anyelement)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_append'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION count_distinct(internal)
    RETURNS bigint
    AS 'count_distinct', 'count_distinct'
    LANGUAGE C IMMUTABLE;

/* serialize data */
CREATE OR REPLACE FUNCTION count_distinct_serial(p_pointer internal)
    RETURNS bytea
    AS 'count_distinct', 'count_distinct_serial'
    LANGUAGE C IMMUTABLE;

/* deserialize data */
CREATE OR REPLACE FUNCTION count_distinct_deserial(p_value bytea, p_dummy internal)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_deserial'
    LANGUAGE C IMMUTABLE;

/* combine data */
CREATE OR REPLACE FUNCTION count_distinct_combine(p_state_1 internal, p_state_2 internal)
    RETURNS internal
    AS 'count_distinct', 'count_distinct_combine'
    LANGUAGE C IMMUTABLE;

CREATE AGGREGATE count_distinct(anyelement) (
    SFUNC = count_distinct_append,
    STYPE = internal,
    FINALFUNC = count_distinct,
    COMBINEFUNC = count_distinct_combine,
    SERIALFUNC = count_distinct_serial,
    DESERIALFUNC = count_distinct_deserial,
    PARALLEL = SAFE
);
