#!/bin/bash
# Import crossings from csv file to crossings table
# must run r/import-crossings.R first to generate csv file
# usage: ./crossings.sh <dbname> ../../r/csv/crossings.csv

set -eu

DB=$1
FILE=$2

echo Importing "$FILE" to table crossings...

psql -d "$DB" -c "
DROP TABLE IF EXISTS crossings_import;
CREATE TABLE crossings_import (
  id SERIAL PRIMARY KEY,
  x_coord REAL,
  y_coord REAL
);
"
psql -d "$DB" -c "\copy crossings_import(id, x_coord, y_coord) FROM '$FILE' WITH CSV HEADER"
psql -d "$DB" -c "
DROP TABLE IF EXISTS crossings;
CREATE TABLE crossings AS (
  WITH c1 AS (
    SELECT
      id,
      x_coord,
      y_coord,
      ST_SetSRID(ST_MakePoint(x_coord, y_coord), 5070) as geom
    FROM crossings_import
  ), c2 AS (
    SELECT
      id,
      x_coord,
      y_coord,
      geom,
      ST_Transform(geom, 4326) as geom_wgs84
    FROM c1
  )
  SELECT
    id,
    x_coord,
    y_coord,
    ST_X(geom_wgs84) AS lon,
    ST_Y(geom_wgs84) AS lat,
    geom,
    geom_wgs84
  FROM c2
);
CREATE INDEX crossings_geom_idx ON crossings USING gist(geom);
CREATE INDEX crossings_geom_wgs84_idx ON crossings USING gist(geom_wgs84);
CREATE INDEX crossings_id_idx ON crossings (id);
"
