#!/bin/bash
# Create crossings-huc lookup table
# usage: ./crossings-huc.sh <dbname>

set -eu

DB=$1

echo Creating crossings_huc table in $DB...
psql -d "$DB" -c "
DROP TABLE IF EXISTS crossings_huc;

CREATE TABLE crossings_huc AS (
  SELECT
    c.id AS crossing_id,
    w.huc12::text AS huc12,
    substr(w.huc12, 1, 10) AS huc10,
    substr(w.huc12, 1, 8) AS huc8,
    substr(w.huc12, 1, 6) AS huc6,
    substr(w.huc12, 1, 4) AS huc4,
    substr(w.huc12, 1, 2) AS huc2
  FROM crossings c, wbdhu12 w
  WHERE ST_Contains(w.geom, c.geom)
);

CREATE INDEX crossings_huc_huc12_idx ON crossings_huc (huc12);
CREATE INDEX crossings_huc_huc10_idx ON crossings_huc (huc10);
CREATE INDEX crossings_huc_huc8_idx ON crossings_huc (huc8);
CREATE INDEX crossings_huc_huc6_idx ON crossings_huc (huc6);
CREATE INDEX crossings_huc_huc4_idx ON crossings_huc (huc4);
CREATE INDEX crossings_huc_huc2_idx ON crossings_huc (huc2);
"

echo Deleting unused hucs in $DB...
psql -d "$DB" -c "DELETE FROM wbdhu12 WHERE huc12 NOT IN (SELECT DISTINCT huc12 FROM crossings_huc);"
psql -d "$DB" -c "DELETE FROM wbdhu10 WHERE huc10 NOT IN (SELECT DISTINCT huc10 FROM crossings_huc);"
psql -d "$DB" -c "DELETE FROM wbdhu8 WHERE huc8 NOT IN (SELECT DISTINCT huc8 FROM crossings_huc);"
psql -d "$DB" -c "DELETE FROM wbdhu6 WHERE huc6 NOT IN (SELECT DISTINCT huc6 FROM crossings_huc);"
psql -d "$DB" -c "DELETE FROM wbdhu4 WHERE huc4 NOT IN (SELECT DISTINCT huc4 FROM crossings_huc);"
