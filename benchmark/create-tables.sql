-- SMALL DATASET (100k rows)

-- correlated columns, same cardinality (identity)
CREATE TABLE small_1 (
    col_a   INT,
    col_b   INT
);

INSERT INTO small_1 SELECT i, i FROM generate_series(1,100000) s(i);

-- different cardinality (second column 10 values)
CREATE TABLE small_10 (
    col_a   INT,
    col_b   INT
);

INSERT INTO small_10 SELECT i, mod(i,10) FROM generate_series(1,100000) s(i);

-- different cardinality (second column 100 values)
CREATE TABLE small_100 (
    col_a   INT,
    col_b   INT
);

INSERT INTO small_100 SELECT i, mod(i,100) FROM generate_series(1,100000) s(i);

-- different cardinality (second column 10000 values)
CREATE TABLE small_10000 (
    col_a   INT,
    col_b   INT
);

INSERT INTO small_10000 SELECT i, mod(i,10000) FROM generate_series(1,100000) s(i);

-- columns with random values and different cardinalities (100k values, 1000 values and 10 values)
CREATE TABLE small_random (
    col_a   INT,
    col_b   INT,
    col_c   INT
);

INSERT INTO small_random SELECT (100000*random())::int, (1000*random()*random())::int, (10*random()*random())::int FROM generate_series(1,100000) s(i);

-- two random columns, but generated to be correlated
CREATE TABLE small_correlated (
    col_a   INT,
    col_b   INT
);

INSERT INTO small_correlated SELECT (i + 100*random())::int, i/1000 FROM generate_series(1,100000) s(i);


ANALYZE small_1;
ANALYZE small_10;
ANALYZE small_100;
ANALYZE small_10000;
ANALYZE small_random;
ANALYZE small_correlated;



-- MEDIUM DATASET (10M rows)

-- correlated columns, same cardinality (identity)
CREATE TABLE medium_1 (
    col_a   INT,
    col_b   INT
);

INSERT INTO medium_1 SELECT i, i FROM generate_series(1,10000000) s(i);

-- different cardinality (second column 10 values)
CREATE TABLE medium_10 (
    col_a   INT,
    col_b   INT
);

INSERT INTO medium_10 SELECT i, mod(i,10) FROM generate_series(1,10000000) s(i);

-- different cardinality (second column 100 values)
CREATE TABLE medium_100 (
    col_a   INT,
    col_b   INT
);

INSERT INTO medium_100 SELECT i, mod(i,100) FROM generate_series(1,10000000) s(i);

-- different cardinality (second column 10000 values)
CREATE TABLE medium_10000 (
    col_a   INT,
    col_b   INT
);

INSERT INTO medium_10000 SELECT i, mod(i,10000) FROM generate_series(1,10000000) s(i);

-- columns with random values and different cardinalities (100k values, 1000 values and 10 values)
CREATE TABLE medium_random (
    col_a   INT,
    col_b   INT,
    col_c   INT
);

INSERT INTO medium_random SELECT (10000000*random())::int, (1000*random()*random())::int, (10*random()*random())::int FROM generate_series(1,10000000) s(i);

-- two random columns, but generated to be correlated
CREATE TABLE medium_correlated (
    col_a   INT,
    col_b   INT
);

INSERT INTO medium_correlated SELECT (i + 100*random())::int, i/1000 FROM generate_series(1,10000000) s(i);


ANALYZE medium_1;
ANALYZE medium_10;
ANALYZE medium_100;
ANALYZE medium_10000;
ANALYZE medium_random;
ANALYZE medium_correlated;



-- LARGE DATASET (100M rows)

-- correlated columns, same cardinality (identity)
CREATE TABLE large_1 (
    col_a   INT,
    col_b   INT
);

INSERT INTO large_1 SELECT i, i FROM generate_series(1,100000000) s(i);

-- different cardinality (second column 10 values)
CREATE TABLE large_10 (
    col_a   INT,
    col_b   INT
);

INSERT INTO large_10 SELECT i, mod(i,10) FROM generate_series(1,100000000) s(i);

-- different cardinality (second column 100 values)
CREATE TABLE large_100 (
    col_a   INT,
    col_b   INT
);

INSERT INTO large_100 SELECT i, mod(i,100) FROM generate_series(1,100000000) s(i);

-- different cardinality (second column 10000 values)
CREATE TABLE large_10000 (
    col_a   INT,
    col_b   INT
);

INSERT INTO large_10000 SELECT i, mod(i,10000) FROM generate_series(1,100000000) s(i);

-- columns with random values and different cardinalities (100k values, 1000 values and 10 values)
CREATE TABLE large_random (
    col_a   INT,
    col_b   INT,
    col_c   INT
);

INSERT INTO large_random SELECT (100000000*random())::int, (1000*random()*random())::int, (10*random()*random())::int FROM generate_series(1,100000000) s(i);

-- two random columns, but generated to be correlated
CREATE TABLE large_correlated (
    col_a   INT,
    col_b   INT
);

INSERT INTO large_correlated SELECT (i + 100*random())::int, i/1000 FROM generate_series(1,100000000) s(i);


ANALYZE large_1;
ANALYZE large_10;
ANALYZE large_100;
ANALYZE large_10000;
ANALYZE large_random;
ANALYZE large_correlated;