// algorithm

const jStat = require('jStat');
let {nodes, edges, targets} = require('./test-data');

const internode = 200;
const tilesize = 400;
const bandwidth = 5000;
const search = 1.5;
const cellsize = 30;
const fudge = 75;
const scaleby = 0.001;
const multiplier = 1000 * 0.2495 * 24;
const bench = 62620.5;

edges.forEach((e, i) => {
  e.index = i;
});

console.log('sum(node.cost)', jStat.sum(nodes.map(d => d.cost)));
console.log('sum(node.upgrades)', jStat.sum(nodes.map(d => d.upgrades)));
console.log('sum(edge.cost)', jStat.sum(edges.map(d => d.cost)));
console.log('sum(edge.value)', jStat.sum(edges.map(d => d.value)));

function graph_linkages(targets, nodes, edges) {
  const n_targets = targets.length;
  const n_nodes = nodes.length;
  const n_edges = edges.length;

  const nodeids = nodes.map(n => n.nodeid);

  function graph_kernel(nodecosts) {
    function graph_kernel_edge(edge) {
      let kern = new Array(n_edges).fill(0);

      const account = bandwidth * 3 / cellsize;
      kern[edge.index] = account;

      function graph_kernel_spread(edge, direction, account) {
        const n = nodeids.indexOf(edge["node" + direction]);
        const nodeid = nodeids[n];

        const a = account - nodecosts[n];
        
        if (a <= 0) return;
        
        const adjacent_edges = edges.filter((e) => {
          return (e.node1 === nodeid || e.node2 === nodeid) && e !== edge;
        });

        if (adjacent_edges.length === 0) return;

        for (let i = 0; i < adjacent_edges.length; i++ ) {
          kern[adjacent_edges[i].index] = a > adjacent_edges[i].cost ? a - adjacent_edges[i].cost : 0;
          if (kern[adjacent_edges[i].index] <= 0) return;
          graph_kernel_spread(adjacent_edges[i], (adjacent_edges[i].node1 == nodeid ? 2 : 1), kern[adjacent_edges[i].index]);
        }
      }

      graph_kernel_spread(edge, 1, account);
      graph_kernel_spread(edge, 2, account);
      
      return kern.map(k => multiplier * (k > 0 ? 1 : 0) * jStat.normal.pdf(3 - k / (bandwidth / cellsize), 0, 1) / bench);
    }

    // for each edge, compute base kernel
    const edge_results = edges.map((e) => {
      const raw_kernel = graph_kernel_edge(e);
      const scaled_kernel = raw_kernel.map(k => k * e.length / cellsize);
      if (e.index == 5) {
        console.log('i=6', raw_kernel, scaled_kernel);
      }
      return scaled_kernel;
    })

    // compute sum of edge kernels and scale by number of cells per edge
    const kernel = edge_results.reduce((p, v) => {
        for (let i = 0, n = p.length; i < n; i++) {
          p[i] += v[i];
        }
        return p;
      }, new Array(n_edges).fill(0))
      .map((v, i) => v * edges[i].length / cellsize);

    return kernel;
  }

  const base_kernel = graph_kernel(nodes.map(d => d.cost));
  const alt_kernel = graph_kernel(nodes.map(d => d.upgrades));

  const deltas = base_kernel.map((b, i) => (alt_kernel[i] - b) / scaleby);
  const effects = deltas.map((d, i) => d * edges[i].value / (edges[i].length / cellsize));
  
  const delta = jStat.sum(deltas);
  const effect = jStat.sum(effects);

  return {
    delta,
    effect,
    deltas,
    effects,
    kernels: {
      base: base_kernel,
      alt: alt_kernel
    }
  };
}

const results = graph_linkages(targets, nodes, edges);
console.log(results, jStat.sum(results.kernels.base), jStat.sum(results.kernels.alt));

// performance test
// const n_trials = 1000;
// const start = performance.now();
// for(let i = 0; i < n_trials; i++) {
//   graph_linkages(targets, nodes, edges);
// }
// const end = performance.now();

// console.log((end - start)/n_trials, "ms");
