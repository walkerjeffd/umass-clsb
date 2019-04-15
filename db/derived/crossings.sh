#!/bin/bash
# Create crossings table from nodes_csv table
# usage: ./crossings.sh

set -eu

. ../../config.sh

echo Creating table crossings from nodes_csv...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
DROP TABLE IF EXISTS crossings;
CREATE TABLE crossings (
  id TEXT PRIMARY KEY UNIQUE,
  node_id BIGINT,
  x REAL,
  y REAL,
  delta REAL,
  effect REAL,
  effect_ln REAL,
  surveyed BOOLEAN,
  aquatic REAL,
  lat REAL,
  lon REAL,
  geom GEOMETRY(POINT, 5070)
);
INSERT INTO crossings (
  WITH d AS (
    SELECT COALESCE(xycode, 'node' || id) AS id, id AS node_id, x, y, delta, effect, effect_ln, surveyed::boolean, aquatic, lat, lon, geom, row_number() OVER (PARTITION BY xycode ORDER BY delta DESC) AS rank
    FROM nodes_csv
    WHERE what='crossing'
  )
  SELECT id, node_id, x, y, delta, effect, effect_ln, surveyed, aquatic, lat, lon, geom
  FROM d
  WHERE rank = 1
);
"

echo Done!
