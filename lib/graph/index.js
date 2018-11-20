/* eslint-disable no-plusplus */

const jStat = require('jStat');

const bandwidth = 5000;
const cellsize = 30;
const scaleby = 0.001;
const multiplier = 1000 * 0.2495 * 4.88;
const bench = 62620.5;

function trim(targets, nodes, edges) {
  // R code: trim.along.graph()
  // arguments:
  //   targets: [{id, node_id}, ...]
  //   nodes: [{node_id, cost}, ...]
  //   edges: [{start_id, end_id, cost}, ...]
  // returns: {
  //   nodes: [{node_id, cost}, ...]
  //   edges: [{index, start_id, end_id, cost}, ...]
  // }

  edges.forEach((e, i) => {
    e.index = i;
  });

  const nodeIds = nodes.map(n => n.node_id);
  const account = (bandwidth * 3) / cellsize;
  const kern = new Array(edges.length).fill(0);

  const targetIds = targets.map(d => d.node_id);
  const nodecosts = nodes.map(n => (targetIds.includes(n.node_id) ? 0 : n.cost));

  function graphKernelSpread(e, direction, accountTotal) {
    const n = nodeIds.indexOf(e[direction]);
    const nodeId = nodeIds[n];

    const a = accountTotal - nodecosts[n];

    if (a <= 0) return;

    const adjacentEdges = edges.filter(d =>
      ((d.start_id === nodeId || d.end_id === nodeId) && d !== e));

    if (adjacentEdges.length === 0) return;

    for (let i = 0; i < adjacentEdges.length; i++) {
      kern[adjacentEdges[i].index] = a > adjacentEdges[i].cost ? a - adjacentEdges[i].cost : 0;

      if (kern[adjacentEdges[i].index] <= 0) return;

      graphKernelSpread(
        adjacentEdges[i],
        (adjacentEdges[i].start_id === nodeId ? 'end_id' : 'start_id'),
        kern[adjacentEdges[i].index]
      );
    }
  }

  let edgeRows = edges.filter(d => targetIds.includes(d.start_id)).map(d => d.index);

  if (edgeRows.length > 0) {
    for (let j = 0; j < edgeRows.length; j++) {
      graphKernelSpread(edges[edgeRows[j]], 'end_id', account);
    }

    edgeRows.forEach((i) => {
      kern[i] = 1;
    });
  }

  edgeRows = edges.filter(d => targetIds.includes(d.end_id)).map(d => d.index);
  if (edgeRows.length > 0) {
    for (let j = 0; j < edgeRows.length; j++) {
      graphKernelSpread(edges[edgeRows[j]], 'start_id', account);
    }

    edgeRows.forEach((i) => {
      kern[i] = 1;
    });
  }

  const trimmedEdges = edges.filter(e => kern[e.index] !== 0);

  const trimmedEdgesStartNodes = trimmedEdges.map(e => e.start_id);
  const trimmedEdgesEndNodes = trimmedEdges.map(e => e.end_id);
  const trimmedNodes = nodes
    .filter(n =>
      trimmedEdgesStartNodes.includes(n.node_id) || trimmedEdgesEndNodes.includes(n.node_id));

  trimmedEdges.forEach((e, i) => {
    e.index = i;
  });

  return {
    edges: trimmedEdges,
    nodes: trimmedNodes
  };
}

function kernel(targets, nodes, edges, nodecosts) {
  const nEdges = edges.length;
  const nodeIds = nodes.map(n => n.node_id);

  edges.forEach((d, i) => {
    d.index = i;
  });

  function graphKernelEdge(edge) {
    const kern = new Array(nEdges).fill(0);

    const account = (bandwidth * 3) / cellsize;
    kern[edge.index] = account;

    function graphKernelSpread(e, direction, accountTotal) {
      const n = nodeIds.indexOf(e[direction]);
      const nodeId = nodeIds[n];

      const a = accountTotal - nodecosts[n];

      if (a <= 0) return;

      const adjacentEdges = edges.filter(d =>
        ((d.start_id === nodeId || d.end_id === nodeId) && d !== e));

      if (adjacentEdges.length === 0) return;

      for (let i = 0; i < adjacentEdges.length; i++) {
        kern[adjacentEdges[i].index] = a > adjacentEdges[i].cost ? a - adjacentEdges[i].cost : 0;
        if (kern[adjacentEdges[i].index] <= 0) return;
        graphKernelSpread(
          adjacentEdges[i],
          (adjacentEdges[i].start_id === nodeId ? 'end_id' : 'start_id'),
          kern[adjacentEdges[i].index]
        );
      }
    }

    graphKernelSpread(edge, 'start_id', account);
    graphKernelSpread(edge, 'end_id', account);

    return kern.map((k) => {
      const z = jStat.normal.pdf(3 - (k / (bandwidth / cellsize)), 0, 1);
      return ((multiplier * (k > 0 ? 1 : 0)) * z) / bench;
    });
  }

  // for each edge, compute base kernel
  const edgeResults = edges.map((e) => {
    const rawKernel = graphKernelEdge(e);
    const scaledKernel = rawKernel.map(k => (k * e.length) / cellsize);
    return scaledKernel;
  });

  // compute sum of edge kernels and scale by number of cells per edge
  const kern = edgeResults.reduce((p, v) => {
    for (let i = 0, n = p.length; i < n; i++) {
      p[i] += v[i];
    }
    return p;
  }, new Array(nEdges).fill(0))
    .map((v, i) => (v * edges[i].length) / cellsize);

  return kern;
}

function linkages(targets, nodes, edges) {
  const targetNodeIds = targets.map(d => d.node_id);

  const base = kernel(targets, nodes, edges, nodes.map(d => d.cost));
  const alt = kernel(targets, nodes, edges, nodes.map(d =>
    (targetNodeIds.includes(d.node_id) ? 0 : d.cost)));

  const deltas = base.map((b, i) => (alt[i] - b) / scaleby);
  const effects = deltas.map((d, i) => (d * edges[i].value) / (edges[i].length / cellsize));

  return {
    delta: {
      total: jStat.sum(deltas),
      values: deltas
    },
    effect: {
      total: jStat.sum(effects),
      values: effects
    },
    kernels: {
      base,
      alt
    }
  };
}

module.exports = {
  trim,
  kernel,
  linkages
};
