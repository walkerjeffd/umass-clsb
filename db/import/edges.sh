#!/bin/bash
# Import graph edges from csv file to edges table
# run r/db-graph.R first to generate csv file
# nodes must already be imported
# usage: ./edges.sh <dbname> ../../r/csv/graph-edges.csv

set -eu

DB=$1
FILE=$2


echo Creating schema...
psql -d "$DB" -c "
DROP TABLE IF EXISTS edges;
CREATE TABLE edges (
  id SERIAL PRIMARY KEY,
  start_id BIGINT REFERENCES nodes(id),
  end_id BIGINT REFERENCES nodes(id),
  length INT,
  cost REAL,
  value REAL,
  geom GEOMETRY(LINESTRING, 5070)
);
ALTER TABLE edges ADD CONSTRAINT edges_start_id_end_id_unique UNIQUE (start_id, end_id);
"

echo Importing "$FILE" to table edges...
psql -d "$DB" -c "\copy edges(start_id, end_id, length, cost, value) FROM '$FILE' WITH CSV HEADER"

echo Setting geom column...
psql -d "$DB" -c "UPDATE edges SET geom=ST_SetSRID(ST_MakeLine(n1.geom, n2.geom), 5070) FROM nodes n1, nodes n2 WHERE start_id=n1.id AND end_id=n2.id;"

echo Creating indices...
psql -d "$DB" -c "CREATE INDEX edges_geom_idx ON edges USING gist(geom);"

echo Done!
