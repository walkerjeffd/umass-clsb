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

module.exports = {
  getTest,
  getNodes,
  getEdges,
  getNetwork
};
