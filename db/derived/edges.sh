#!/bin/bash
# Create edges table from edges_csv
# must run derived/nodes.sh first due to foreign key constraint
# usage: ./edges.sh

set -eu

. ../../config.sh

echo Creating edges table...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
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
INSERT INTO edges (start_id, end_id, length, cost, value) (
  SELECT start_id, end_id, length, cost, value
  FROM edges_csv
);
ALTER TABLE edges ADD CONSTRAINT edges_start_id_end_id_unique UNIQUE (start_id, end_id);
"

echo Setting geom column...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
UPDATE edges SET
  geom=ST_SetSRID(ST_MakeLine(n1.geom, n2.geom), 5070)
  FROM nodes n1, nodes n2
  WHERE start_id=n1.id AND end_id=n2.id;
"

echo Creating indices...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
CREATE INDEX edges_geom_idx ON edges USING gist(geom);
CREATE INDEX edges_start_id_idx ON edges(start_id);
CREATE INDEX edges_end_id_idx ON edges(end_id);
"

echo Done!
