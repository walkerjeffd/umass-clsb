// const config = require('../config');

const config = {
  db: {
    host: 'localhost',
    database: 'clsb',
    user: 'jeff',
    password: '',
    port: 5432
  }
};

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
    SELECT id, x_coord, y_coord, effect, effect_ln, delta, type, lat, lon
    FROM barriers
    WHERE id = ANY (:barrierIds)
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
    SELECT DISTINCT n.id AS nodeid, n.x, n.y, n.cost
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
    .then(barriers => getNodes(barrierIds).then(nodes => ({ barriers, nodes })))
    .then(({ barriers, nodes }) => getEdges(nodes.map(d => d.nodeid))
      .then(edges => ({ edges, nodes, barriers })));
}

function getBarriersInGeoJSON(feature) {
  const sql = `
    SELECT id, x_coord::real, y_coord::real, effect::real, effect_ln::real, delta::real, type, lat, lon
    FROM barriers b
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
  getNodes,
  getEdges,
  getNetwork,
  getBarriersInGeoJSON
};
