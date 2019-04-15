#!/bin/bash
# Import graph nodes from csv file to nodes_csv table
# must run r/db-graph.R first to generate csv file
# usage: ./nodes_csv.sh <dbname> ../../r/csv/graph-nodes.csv

set -eu

FILE=$1

. ../../config.sh

echo Creating schema for nodes_csv tables...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
DROP TABLE IF EXISTS nodes_csv;
CREATE TABLE nodes_csv (
  id BIGINT PRIMARY KEY UNIQUE,
  x REAL,
  y REAL,
  cost REAL,
  what TEXT,
  xycode TEXT,
  damid TEXT,
  aquatic REAL,
  surveyed INT,
  no_crossing INT,
  delta REAL,
  effect REAL,
  effect_ln REAL,
  lat REAL,
  lon REAL,
  geom GEOMETRY(POINT, 5070)
);
"

echo Importing "$FILE" to table nodes_csv...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "\copy nodes_csv(id, x, y, cost, what, xycode, damid, aquatic, surveyed, no_crossing, delta, effect) FROM '$FILE' WITH CSV HEADER"

echo Setting geom column...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
UPDATE nodes_csv SET geom=ST_SetSRID(ST_MakePoint(x, y), 5070);
"

echo Setting lat/lon columns...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
UPDATE nodes_csv SET lat=ST_Y(ST_Transform(geom, 4326)), lon=ST_X(ST_Transform(geom, 4326));
"

echo Setting effect_ln column...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
UPDATE nodes_csv SET effect_ln=LN(effect + 1);
"

echo Done!
