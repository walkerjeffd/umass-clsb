#!/bin/bash
# Merge crossings and dams tables into barriers table
# usage: ./barriers.sh

set -eu

. ../../config.sh

echo Merging crossings and dams into barriers table...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
DROP TABLE IF EXISTS barriers;
CREATE TABLE barriers AS (
  SELECT 'c-' || id as id, x_coord, y_coord, effect, effect_ln, delta, surveyed::integer::boolean as surveyed, aquatic, 'crossing' AS type, geom FROM crossings
  UNION
  SELECT 'd-' || damid as id, x_coord, y_coord, effect, effect_ln, delta, false as surveyed, 0.0 as aquatic, 'dam' AS type, geom FROM dams
);
ALTER TABLE barriers ADD COLUMN lat REAL, ADD COLUMN lon REAL;
UPDATE barriers SET
  lat = ST_Y(ST_Transform(geom, 4326)),
  lon = ST_X(ST_Transform(geom, 4326));

CREATE INDEX barriers_geom_idx ON barriers USING gist(geom);
CREATE INDEX barriers_type_idx ON barriers(type);
CREATE INDEX barriers_id_idx ON barriers(id);
"
echo done
