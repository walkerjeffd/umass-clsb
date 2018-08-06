const jStat = require('jStat');

const bandwidth = 5000;
const cellsize = 30;
const scaleby = 0.001;
const multiplier = 1000 * 0.2495 * 4.88;
const bench = 62620.5;

function trim(targets, nodes, edges) {
  edges.forEach((e, i) => {
    e.index = i;
  });

  const nodeids = nodes.map(n => n.nodeid);
  const account = bandwidth * 3 / cellsize;
  const kern = new Array(edges.length).fill(0);

  const targetIds = targets.map(d => d.nodeid);

  const nodecosts = nodes.map(n => (targetIds.includes(n.nodeid) ? 0 : n.cost));

  function graphKernelSpread(e, direction, accountTotal) {
    const n = nodeids.indexOf(e[`node${direction}`]);
    const nodeid = nodeids[n];

    const a = accountTotal - nodecosts[n];

    if (a <= 0) return;

    const adjacentEdges = edges.filter(
      d => ((d.node1 === nodeid || d.node2 === nodeid) && d !== e)
    );

    if (adjacentEdges.length === 0) return;

    for (let i = 0; i < adjacentEdges.length; i++) {
      kern[adjacentEdges[i].index] = a > adjacentEdges[i].cost ? a - adjacentEdges[i].cost : 0;

      if (kern[adjacentEdges[i].index] <= 0) return;

      graphKernelSpread(
        adjacentEdges[i],
        (adjacentEdges[i].node1 === nodeid ? 2 : 1),
        kern[adjacentEdges[i].index]
      );
    }
  }

  let edgeRows = edges.filter(d => targetIds.includes(d.node1)).map(d => d.index);

  if (edgeRows.length > 0) {
    edgeRows.forEach((i) => {
      kern[i] = 1;
    });

    for (let j = 0; j < edgeRows.length; j++) {
      graphKernelSpread(edges[edgeRows[j]], 2, account);
    }
  }

  edgeRows = edges.filter(d => targetIds.includes(d.node2)).map(d => d.index);
  if (edgeRows.length > 0) {
    edgeRows.forEach((i) => {
      kern[i] = 1;
    });

    for (let j = 0; j < edgeRows.length; j++) {
      graphKernelSpread(edges[edgeRows[j]], 1, account);
    }
  }

  const trimmedEdges = edges.filter(e => kern[e.index] !== 0);

  const trimmedEdgesStartNodes = trimmedEdges.map(e => e.node1);
  const trimmedEdgesEndNodes = trimmedEdges.map(e => e.node2);

  const trimmedNodes = nodes
    .filter(
      n => trimmedEdgesStartNodes.includes(n.nodeid) || trimmedEdgesEndNodes.includes(n.nodeid)
    );

  return {
    edges: trimmedEdges,
    nodes: trimmedNodes
  };
}

function kernel(targets, nodes, edges, nodecosts) {
  const nEdges = edges.length;
  const nodeids = nodes.map(n => n.nodeid);

  function graphKernelEdge(edge) {
    const kern = new Array(nEdges).fill(0);

    const account = bandwidth * 3 / cellsize;
    kern[edge.index] = account;

    function graphKernelSpread(e, direction, accountTotal) {
      const n = nodeids.indexOf(e[`node${direction}`]);
      const nodeid = nodeids[n];

      const a = accountTotal - nodecosts[n];

      if (a <= 0) return;

      const adjacentEdges = edges.filter(
        d => ((d.node1 === nodeid || d.node2 === nodeid) && d !== e)
      );

      if (adjacentEdges.length === 0) return;

      for (let i = 0; i < adjacentEdges.length; i++) {
        kern[adjacentEdges[i].index] = a > adjacentEdges[i].cost ? a - adjacentEdges[i].cost : 0;
        if (kern[adjacentEdges[i].index] <= 0) return;
        graphKernelSpread(
          adjacentEdges[i],
          (adjacentEdges[i].node1 === nodeid ? 2 : 1),
          kern[adjacentEdges[i].index]
        );
      }
    }

    graphKernelSpread(edge, 1, account);
    graphKernelSpread(edge, 2, account);

    return kern.map(
      k => multiplier
        * (k > 0 ? 1 : 0)
        * jStat.normal.pdf(3 - k / (bandwidth / cellsize), 0, 1) / bench
    );
  }

  // for each edge, compute base kernel
  const edgeResults = edges.map((e) => {
    const rawKernel = graphKernelEdge(e);
    const scaledKernel = rawKernel.map(k => k * e.length / cellsize);
    return scaledKernel;
  });

  // compute sum of edge kernels and scale by number of cells per edge
  const kern = edgeResults.reduce((p, v) => {
    for (let i = 0, n = p.length; i < n; i++) {
      p[i] += v[i];
    }
    return p;
  }, new Array(nEdges).fill(0))
    .map((v, i) => v * edges[i].length / cellsize);

  return kern;
}

function linkages(targets, nodes, edges) {
  // const nTargets = targets.length;
  // const nNodes = nodes.length;

  const base = kernel(targets, nodes, edges, nodes.map(d => d.cost));
  const alt = kernel(targets, nodes, edges, nodes.map(d => d.upgrades));

  const deltas = base.map((b, i) => (alt[i] - b) / scaleby);
  const effects = deltas.map((d, i) => d * edges[i].value / (edges[i].length / cellsize));

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
