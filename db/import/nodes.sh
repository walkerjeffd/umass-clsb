#!/bin/bash
# Import graph nodes from csv file to nodes table
# must run r/db-graph.R first to generate csv file
# usage: ./nodes.sh <dbname> ../../r/csv/graph-nodes.csv

set -eu

DB=$1
FILE=$2

echo Creating schema for nodes tables...
psql -d "$DB" -c "
DROP TABLE IF EXISTS nodes;
CREATE TABLE nodes (
  id BIGINT PRIMARY KEY UNIQUE,
  x REAL,
  y REAL,
  lat REAL,
  lon REAL,
  cost REAL,
  geom GEOMETRY(POINT, 5070)
);
"

echo Importing "$FILE" to table nodes...
psql -d "$DB" -c "\copy nodes(id, x, y, cost) FROM '$FILE' WITH CSV HEADER"

echo Setting geom column...
psql -d "$DB" -c "UPDATE nodes SET geom=ST_SetSRID(ST_MakePoint(x, y), 5070);"

echo Setting lat/lon columns...
psql -d "$DB" -c "UPDATE nodes SET lat=ST_Y(ST_Transform(geom, 4326)), lon=ST_X(ST_Transform(geom, 4326));"

echo Creating indices...
psql -d "$DB" -c "CREATE INDEX nodes_geom_idx ON nodes USING gist(geom);"

echo Done!
