MODULE_big = count_distinct
OBJS = src/count_distinct.o

EXTENSION = count_distinct
DATA = sql/count_distinct--1.1.0.sql
MODULES = count_distinct

CFLAGS=`pg_config --includedir-server`

TESTS        = $(wildcard test/sql/*.sql)
REGRESS      = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --inputdir=test

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

count_distinct.so: src/count_distinct.o

src/count_distinct.o: src/count_distinct.c
