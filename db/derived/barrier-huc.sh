#!/bin/bash
# Create barrier-huc lookup table
# usage: ./barrier-huc.sh

set -eu

. ../../config.sh

echo Creating barrier_huc table...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
DROP TABLE IF EXISTS barrier_huc;

CREATE TABLE barrier_huc AS (
  SELECT
    b.id AS barrier_id,
    w.huc12::text AS huc12,
    substr(w.huc12, 1, 10) AS huc10,
    substr(w.huc12, 1, 8) AS huc8,
    substr(w.huc12, 1, 6) AS huc6,
    substr(w.huc12, 1, 4) AS huc4,
    substr(w.huc12, 1, 2) AS huc2
  FROM barriers b, wbdhu12 w
  WHERE ST_Contains(w.geom, b.geom)
);

CREATE INDEX barrier_huc_huc12_idx ON barrier_huc (huc12);
CREATE INDEX barrier_huc_huc10_idx ON barrier_huc (huc10);
CREATE INDEX barrier_huc_huc8_idx ON barrier_huc (huc8);
CREATE INDEX barrier_huc_huc6_idx ON barrier_huc (huc6);
CREATE INDEX barrier_huc_huc4_idx ON barrier_huc (huc4);
CREATE INDEX barrier_huc_huc2_idx ON barrier_huc (huc2);
"

echo Deleting unused hucs...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
DELETE FROM wbdhu12 WHERE huc12 NOT IN (SELECT DISTINCT huc12 FROM barrier_huc);
DELETE FROM wbdhu10 WHERE huc10 NOT IN (SELECT DISTINCT huc10 FROM barrier_huc);
DELETE FROM wbdhu8 WHERE huc8 NOT IN (SELECT DISTINCT huc8 FROM barrier_huc);
DELETE FROM wbdhu6 WHERE huc6 NOT IN (SELECT DISTINCT huc6 FROM barrier_huc);
DELETE FROM wbdhu4 WHERE huc4 NOT IN (SELECT DISTINCT huc4 FROM barrier_huc);
"
