DO $$
BEGIN
       IF (
              SELECT TRUE
              FROM pg_attribute
              WHERE attrelid = 'pg_catalog.pg_aggregate'::regclass
                AND attname = 'aggcombinefn'
       )
       THEN
              DROP AGGREGATE count_distinct(anyelement);
              /* Server supports parallel aggregation (9.6+) */

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

              /* Create the aggregate function itself */
              CREATE AGGREGATE count_distinct(anyelement) (
                     SFUNC = count_distinct_append,
                     STYPE = internal,
                     FINALFUNC = count_distinct,
                     COMBINEFUNC = count_distinct_combine,
                     SERIALFUNC = count_distinct_serial,
                     DESERIALFUNC = count_distinct_deserial,
                     PARALLEL = SAFE
              );
       END IF;
END;
$$;
