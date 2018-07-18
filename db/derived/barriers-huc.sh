#!/bin/bash
# Create barriers-huc lookup table
# usage: ./barriers-huc.sh

set -eu

. ../../config.sh

echo Creating barriers_huc table...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
DROP TABLE IF EXISTS barriers_huc;

CREATE TABLE barriers_huc AS (
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

CREATE INDEX barriers_huc_huc12_idx ON barriers_huc (huc12);
CREATE INDEX barriers_huc_huc10_idx ON barriers_huc (huc10);
CREATE INDEX barriers_huc_huc8_idx ON barriers_huc (huc8);
CREATE INDEX barriers_huc_huc6_idx ON barriers_huc (huc6);
CREATE INDEX barriers_huc_huc4_idx ON barriers_huc (huc4);
CREATE INDEX barriers_huc_huc2_idx ON barriers_huc (huc2);
"

echo Deleting unused hucs...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
DELETE FROM wbdhu12 WHERE huc12 NOT IN (SELECT DISTINCT huc12 FROM barriers_huc);
DELETE FROM wbdhu10 WHERE huc10 NOT IN (SELECT DISTINCT huc10 FROM barriers_huc);
DELETE FROM wbdhu8 WHERE huc8 NOT IN (SELECT DISTINCT huc8 FROM barriers_huc);
DELETE FROM wbdhu6 WHERE huc6 NOT IN (SELECT DISTINCT huc6 FROM barriers_huc);
DELETE FROM wbdhu4 WHERE huc4 NOT IN (SELECT DISTINCT huc4 FROM barriers_huc);
"
