BEGIN;

CREATE EXTENSION count_distinct;

-- int
SELECT count_distinct(x::int) FROM generate_series(1,1000) s(x);
SELECT count_distinct(mod(x,10)::int) FROM generate_series(1,1000) s(x);

-- bigint
SELECT count_distinct(x::bigint) FROM generate_series(1,1000) s(x);
SELECT count_distinct(mod(x,10)::bigint) FROM generate_series(1,1000) s(x);

ROLLBACK;