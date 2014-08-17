\timing off

EXPLAIN SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM small_1) AS foo;
EXPLAIN SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM small_1) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10 GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10 GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_100 GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_100 GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10000 GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10000 GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_1 GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_1 GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_random GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM small_random GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_correlated GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_correlated GROUP BY col_a) AS foo;

EXPLAIN SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM medium_1) AS foo;
EXPLAIN SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM medium_1) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10 GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10 GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_100 GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_100 GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10000 GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10000 GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_1 GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_1 GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_random GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM medium_random GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_correlated GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_correlated GROUP BY col_a) AS foo;

EXPLAIN SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM large_1) AS foo;
EXPLAIN SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM large_1) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10 GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10 GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_100 GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_100 GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10000 GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10000 GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_1 GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_1 GROUP BY col_a) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM large_random GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_correlated GROUP BY col_b) AS foo;
EXPLAIN SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_correlated GROUP BY col_a) AS foo;

\timing on

\echo SMALL QUERY 1
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM small_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM small_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM small_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM small_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM small_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM small_1) AS foo;

\echo SMALL QUERY 2
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM small_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM small_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM small_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM small_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM small_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM small_1) AS foo;

\echo SMALL QUERY 3
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10 GROUP BY col_b) AS foo;

\echo SMALL QUERY 4
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10 GROUP BY col_a) AS foo;

\echo SMALL QUERY 5
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_100 GROUP BY col_b) AS foo;

\echo SMALL QUERY 6
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_100 GROUP BY col_a) AS foo;

\echo SMALL QUERY 7
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_10000 GROUP BY col_b) AS foo;

\echo SMALL QUERY 8
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_10000 GROUP BY col_a) AS foo;

\echo SMALL QUERY 9
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_1 GROUP BY col_b) AS foo;

\echo SMALL QUERY 10
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_1 GROUP BY col_a) AS foo;

\echo SMALL QUERY 11
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;

\echo SMALL QUERY 12
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_random GROUP BY col_a) AS foo;

\echo SMALL QUERY 13
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM small_random GROUP BY col_b) AS foo;

\echo SMALL QUERY 14
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_random GROUP BY col_b) AS foo;

\echo SMALL QUERY 15
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM small_correlated GROUP BY col_b) AS foo;

\echo SMALL QUERY 16
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM small_correlated GROUP BY col_a) AS foo;


\echo MEDIUM QUERY 1
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM medium_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM medium_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM medium_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM medium_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM medium_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM medium_1) AS foo;

\echo MEDIUM QUERY 2
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM medium_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM medium_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM medium_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM medium_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM medium_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM medium_1) AS foo;

\echo MEDIUM QUERY 3
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10 GROUP BY col_b) AS foo;

\echo MEDIUM QUERY 4
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10 GROUP BY col_a) AS foo;

\echo MEDIUM QUERY 5
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_100 GROUP BY col_b) AS foo;

\echo MEDIUM QUERY 6
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_100 GROUP BY col_a) AS foo;

\echo MEDIUM QUERY 7
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_10000 GROUP BY col_b) AS foo;

\echo MEDIUM QUERY 8
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_10000 GROUP BY col_a) AS foo;

\echo MEDIUM QUERY 9
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_1 GROUP BY col_b) AS foo;

\echo MEDIUM QUERY 10
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_1 GROUP BY col_a) AS foo;

\echo MEDIUM QUERY 11
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;

\echo MEDIUM QUERY 12
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_random GROUP BY col_a) AS foo;

\echo MEDIUM QUERY 13
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM medium_random GROUP BY col_b) AS foo;

\echo MEDIUM QUERY 14
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_random GROUP BY col_b) AS foo;

\echo MEDIUM QUERY 15
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM medium_correlated GROUP BY col_b) AS foo;

\echo MEDIUM QUERY 16
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM medium_correlated GROUP BY col_a) AS foo;



\echo LARGE QUERY 1
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM large_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM large_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM large_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM large_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM large_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_a) AS b FROM large_1) AS foo;

\echo LARGE QUERY 2
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM large_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM large_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM large_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM large_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM large_1) AS foo;
SELECT COUNT(*), AVG(b), SUM(b) FROM (SELECT COUNT(DISTINCT col_b) AS b FROM large_1) AS foo;

\echo LARGE QUERY 3
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10 GROUP BY col_b) AS foo;

\echo LARGE QUERY 4
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10 GROUP BY col_a) AS foo;

\echo LARGE QUERY 5
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_100 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_100 GROUP BY col_b) AS foo;

\echo LARGE QUERY 6
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_100 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_100 GROUP BY col_a) AS foo;

\echo LARGE QUERY 7
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10000 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_10000 GROUP BY col_b) AS foo;

\echo LARGE QUERY 8
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10000 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_10000 GROUP BY col_a) AS foo;

\echo LARGE QUERY 9
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_1 GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_1 GROUP BY col_b) AS foo;

\echo LARGE QUERY 10
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_1 GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_1 GROUP BY col_a) AS foo;

\echo LARGE QUERY 11
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;

\echo LARGE QUERY 12
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_random GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_random GROUP BY col_a) AS foo;

\echo LARGE QUERY 13
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_c) AS b FROM large_random GROUP BY col_b) AS foo;

\echo LARGE QUERY 14
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_random GROUP BY col_b) AS foo;

\echo LARGE QUERY 15
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_correlated GROUP BY col_b) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_b AS a, COUNT(DISTINCT col_a) AS b FROM large_correlated GROUP BY col_b) AS foo;

\echo LARGE QUERY 16
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_correlated GROUP BY col_a) AS foo;
SELECT COUNT(*), COUNT(a), AVG(b), SUM(b) FROM (SELECT col_a AS a, COUNT(DISTINCT col_b) AS b FROM large_correlated GROUP BY col_a) AS foo;
