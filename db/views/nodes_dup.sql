CREATE VIEW nodes_dup AS (
  WITH dup AS (
    SELECT x, y, count(*) AS n
    FROM nodes_csv
    GROUP BY x, y
  )
  SELECT
    n.id,
    n.x,
    n.y,
    dup.n,
    n.geom
   FROM nodes_csv n
     JOIN dup ON n.x = dup.x AND n.y = dup.y
  WHERE dup.n > 1
);
