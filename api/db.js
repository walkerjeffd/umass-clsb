const config = require('./config');

const knex = require('knex')({
  client: 'pg',
  connection: config.db,
});

function getTest() {
  return knex('barriers')
    .count();
}

function getBarriers(barrierIds) {
  const sql = `
    SELECT b.id, b.x_coord::real, b.y_coord::real, b.effect::real, b.effect_ln::real, b.delta::real, b.type, b.lat, b.lon, bn.node_id
    FROM barriers b
    LEFT JOIN barrier_node bn ON b.id = bn.barrier_id
    WHERE b.id = ANY (:barrierIds)
  `;

  const qry = knex
    .raw(sql, {
      barrierIds
    });

  return qry
    .then(result => result.rows);
}

function getNodes(barrierIds) {
  const sql = `
    SELECT DISTINCT n.id AS node_id, n.x, n.y, n.cost
    FROM nodes n, barriers b
    WHERE ST_Contains(ST_Buffer(b.geom, :maxdist), n.geom)
    AND b.id = ANY (:barrierIds)
  `;

  const qry = knex
    .raw(sql, {
      maxdist: 7775,
      barrierIds
    });

  return qry
    .then(result => result.rows);
}

function getEdges(nodeIds) {
  const sql = `
    SELECT DISTINCT id, start_id, end_id, length, cost, value
    FROM edges
    WHERE start_id = ANY (:nodeIds) OR end_id = ANY (:nodeIds)
  `;

  const qry = knex
    .raw(sql, {
      maxdist: 7775,
      nodeIds
    });

  return qry
    .then(result => result.rows);
}

function getNetwork(barrierIds) {
  return getBarriers(barrierIds)
    .then(targets => getNodes(barrierIds)
      .then(nodes => ({ targets, nodes })))
    .then(({ targets, nodes }) => getEdges(nodes.map(d => d.node_id))
      .then(edges => ({ targets, nodes, edges })));
}

function getBarriersInGeoJSON(feature) {
  const sql = `
    SELECT b.id, b.x_coord::real, b.y_coord::real, b.effect::real, b.effect_ln::real, b.delta::real, b.type, b.lat, b.lon, bn.node_id
    FROM barriers b
    LEFT JOIN barrier_node bn ON b.id = bn.barrier_id
    WHERE ST_Within(
      b.geom,
      ST_Transform(
        ST_SetSRID(
          ST_GeomFromGeoJSON(:geometry),
          4326
        ),
        5070
      )
    )
  `;

  const qry = knex
    .raw(sql, {
      geometry: feature.geometry
    });

  return qry
    .then(result => result.rows);
}

module.exports = {
  getTest,
  getBarriers,
  getNodes,
  getEdges,
  getNetwork,
  getBarriersInGeoJSON
};
