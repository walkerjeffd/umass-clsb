#!/bin/bash
# Merge crossings and dams tables into barriers table
# usage: ./barriers.sh

set -eu

. ../../config.sh

echo Merging crossings and dams into barriers table...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
DROP TABLE IF EXISTS barriers;
CREATE TABLE barriers AS (
  SELECT id, node_id, x, y, effect, effect_ln, delta, surveyed, aquatic, 'crossing' AS type, lat, lon, geom FROM crossings
  UNION
  SELECT id, node_id, x, y, effect, effect_ln, delta, false as surveyed, aquatic, 'dam' AS type, lat, lon, geom FROM dams
);

CREATE INDEX barriers_geom_idx ON barriers USING gist(geom);
CREATE INDEX barriers_type_idx ON barriers(type);
CREATE INDEX barriers_id_idx ON barriers(id);
"
echo done
