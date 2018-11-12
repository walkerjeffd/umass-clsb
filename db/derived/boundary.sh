#!/bin/bash
# Merge states into overall boundary
# usage: ./boundary.sh

set -eu

TABLE=boundary

. ../../config.sh

echo Merging states into $TABLE...

psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
CREATE TABLE boundary AS (
  SELECT ST_SetSRID(ST_Union(geom), 4326) AS geom
  FROM states
);
CREATE INDEX boundary_geom_geom_idx ON boundary USING gist(geom);
"
