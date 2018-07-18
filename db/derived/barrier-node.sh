#!/bin/bash
# Create barrier-node lookup table
# usage: ./barrier-node.sh

set -eu

. ../../config.sh

echo Creating barrier_node table...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
DROP TABLE IF EXISTS barrier_node;

CREATE TABLE barrier_node AS (
  WITH c1 AS (
    SELECT
      b.id AS barrier_id,
      n.id AS node_id,
      ST_Distance(b.geom, n.geom) AS dist
    FROM barriers b, nodes n
    WHERE ST_Contains(ST_Expand(b.geom, 75), n.geom)
  ), c2 AS (
    SELECT *, RANK() OVER (PARTITION BY barrier_id ORDER BY dist) as rank
    FROM c1
  )
  SELECT barrier_id, node_id, dist
  FROM c2
  WHERE rank=1
);

CREATE INDEX barrier_node_barrier_id_idx ON barrier_node(barrier_id);
CREATE INDEX barrier_node_node_id_idx ON barrier_node(node_id);
"

