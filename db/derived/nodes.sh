#!/bin/bash
# Create nodes table from nodes_csv
# usage: ./nodes.sh

set -eu

. ../../config.sh

echo Creating nodes table...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
DROP TABLE IF EXISTS nodes;
CREATE TABLE nodes (
  id BIGINT PRIMARY KEY UNIQUE,
  x REAL,
  y REAL,
  cost REAL,
  lat REAL,
  lon REAL,
  geom GEOMETRY(POINT, 5070)
);
INSERT INTO nodes (
  SELECT id, x, y, cost, lat, lon, geom
  FROM nodes_csv
);
"

echo Creating indices...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
CREATE INDEX nodes_geom_idx ON nodes USING gist(geom);
"

echo Done!
