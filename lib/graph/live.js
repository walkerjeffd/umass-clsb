const jStat = require('jStat');
const graph = require('./index');
const { nodes, edges, targets } = require('./test-data');

edges.forEach((e, i) => {
  e.index = i;
});

console.log('sum(node.cost)', jStat.sum(nodes.map(d => d.cost)));
console.log('sum(node.upgrades)', jStat.sum(nodes.map(d => d.upgrades)));
console.log('sum(edge.cost)', jStat.sum(edges.map(d => d.cost)));
console.log('sum(edge.value)', jStat.sum(edges.map(d => d.value)));

const results = graph.linkages(targets, nodes, edges);
console.log(results, jStat.sum(results.kernels.base), jStat.sum(results.kernels.alt));

// performance test
// const n_trials = 1000;
// const start = performance.now();
// for(let i = 0; i < n_trials; i++) {
//   graph_linkages(targets, nodes, edges);
// }
// const end = performance.now();

// console.log((end - start)/n_trials, "ms");