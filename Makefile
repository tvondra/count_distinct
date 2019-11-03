MODULE_big = count_distinct
OBJS = count_distinct.o

EXTENSION = count_distinct
DATA = sql/count_distinct--3.0.1.sql sql/count_distinct--1.3.1--1.3.2.sql \
		sql/count_distinct--1.3.2--1.3.3.sql sql/count_distinct--1.3.3--2.0.0.sql \
		sql/count_distinct--2.0.0--3.0.0.sql sql/count_distinct--3.0.0--3.0.1.sql
MODULES = count_distinct

CFLAGS=`pg_config --includedir-server`

TESTS        = $(wildcard test/sql/*.sql)
REGRESS      = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --inputdir=test

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
