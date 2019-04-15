#!/bin/bash
# Create dams table from nodes_csv table
# usage: ./dams.sh

set -eu

. ../../config.sh

echo Creating table dams from nodes_csv...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
DROP TABLE IF EXISTS dams;
CREATE TABLE dams (
  id TEXT PRIMARY KEY UNIQUE,
  node_id BIGINT,
  x REAL,
  y REAL,
  delta REAL,
  effect REAL,
  effect_ln REAL,
  aquatic REAL,
  lat REAL,
  lon REAL,
  geom GEOMETRY(POINT, 5070)
);
INSERT INTO dams (
  WITH d AS (
    SELECT damid AS id, id AS node_id, x, y, delta, effect, effect_ln, aquatic, lat, lon, geom, row_number() OVER (PARTITION BY damid ORDER BY delta DESC) AS rank
    FROM nodes_csv
    WHERE what='dam'
  )
  SELECT id, node_id, x, y, delta, effect, effect_ln, aquatic, lat, lon, geom
  FROM d
  WHERE rank = 1
);
"

echo Done!
