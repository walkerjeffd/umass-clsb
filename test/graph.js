/* eslint-env mocha */
/* eslint-disable func-names, prefer-arrow-callback */

const chai = require('chai');
const jStat = require('jStat');
const graph = require('../lib/graph/');

const dataEffectsSingle = require('./data/graph-effects-single'); // r/kern
const dataTrimSingle = require('./data/graph-trim-single');
const dataTrimMultiple = require('./data/graph-trim-multiple');

const expect = chai.expect; // eslint-disable-line

describe('graph', function () {
  describe('#data-effects', function () {
    describe('single target', function () {
      const { edges, nodes, targets } = dataEffectsSingle;
      edges.forEach((e, i) => {
        e.index = i;
      });

      it('should have node costs exceed node upgrades', function () {
        const costSum = jStat.sum(nodes.map(d => d.cost));
        const upgradeSum = jStat.sum(nodes.map(d => d.upgrades));
        expect(costSum).to.be.above(upgradeSum);
      });
      it('should have one target', function () {
        expect(targets).to.be.lengthOf(1);
      });
      it('should have one node with upgrades equal to 0', function () {
        const targetNodes = nodes.filter(d => d.cost !== d.upgrades);
        const targetNode = targetNodes[0];

        expect(targetNodes).to.be.lengthOf(1);
        expect(targetNode.upgrades).to.equal(0);
      });
    });
  });

  describe('#data-trim', function () {
    describe('single target', function () {
      const { input, output, targets } = dataTrimSingle;

      it('should have input, output, and targets', function () {
        expect(input).to.be.an('object');
        expect(output).to.be.an('object');
        expect(targets).to.be.an('array');
      });
    });
  });

  describe('#trim()', function () {
    describe('single target', function () {
      const { input, output, targets } = dataTrimSingle;
      const out = graph.trim(targets, input.nodes, input.edges);

      it('should return object with nodes and edges', function () {
        expect(out).to.be.an('object');
        expect(out).to.have.property('nodes');
        expect(out).to.have.property('edges');
      });

      it('should return same nodes as R', function () {
        expect(out.nodes).to.have.lengthOf(output.nodes.length);
        expect(out.nodes.map(d => d.nodeid)).to.deep.equal(output.nodes.map(d => d.nodeid));
      });

      it('should return same edges as R', function () {
        expect(out.edges).to.have.lengthOf(output.edges.length);
        expect(out.edges.map(d => d.node1)).to.deep.equal(output.edges.map(d => d.node1));
        expect(out.edges.map(d => d.node2)).to.deep.equal(output.edges.map(d => d.node2));
      });
    });
    describe('multiple targets', function () {
      const { input, output, targets } = dataTrimMultiple;
      const out = graph.trim(targets, input.nodes, input.edges);

      it('should return object with nodes and edges', function () {
        expect(out).to.be.an('object');
        expect(out).to.have.property('nodes');
        expect(out).to.have.property('edges');
      });

      it('should return same nodes as R', function () {
        expect(out.nodes).to.have.lengthOf(output.nodes.length);
        expect(out.nodes.map(d => d.nodeid)).to.deep.equal(output.nodes.map(d => d.nodeid));
      });

      it('should return same edges as R', function () {
        expect(out.edges).to.have.lengthOf(output.edges.length);
        expect(out.edges.map(d => d.node1)).to.deep.equal(output.edges.map(d => d.node1));
        expect(out.edges.map(d => d.node2)).to.deep.equal(output.edges.map(d => d.node2));
      });
    });
  });

  describe('#kernel()', function () {
    const {
      edges, nodes, targets, kernels
    } = dataEffectsSingle;
    edges.forEach((e, i) => {
      e.index = i;
    });
    const base = graph.kernel(targets, nodes, edges, nodes.map(d => d.cost));
    const alt = graph.kernel(targets, nodes, edges, nodes.map(d => d.upgrades));
    it('should return array with length equal to number of edges', function () {
      expect(base).to.be.a('array').with.lengthOf(edges.length);
    });
    it('should return array of numbers without any NaN', function () {
      base.every(d => expect(d).to.be.a('number').and.not.be.NaN);
    });
    it('should reproduce base kernel for test case', function () {
      expect(base).to.have.lengthOf(kernels.base.length);
      base.every((d, i) => expect(d).to.be.closeTo(kernels.base[i], 0.001));
    });
    it('should reproduce alt kernel for test case', function () {
      expect(alt).to.have.lengthOf(kernels.alt.length);
      alt.every((d, i) => expect(d).to.be.closeTo(kernels.alt[i], 0.001));
    });
  });

  describe('#linkages()', function () {
    const {
      edges, nodes, targets, delta, effect
    } = dataEffectsSingle;
    edges.forEach((e, i) => {
      e.index = i;
    });
    const out = graph.linkages(targets, nodes, edges);
    it('should return object', function () {
      expect(out).to.be.a('object');
      expect(out).to.have.property('delta');
      expect(out.delta).to.have.property('total');
      expect(out.delta).to.have.property('values');
      expect(out).to.have.property('effect');
      expect(out.effect).to.have.property('total');
      expect(out.effect).to.have.property('values');
      expect(out).to.have.property('kernels');
      expect(out.kernels).to.have.property('base');
      expect(out.kernels).to.have.property('alt');
    });
    it('should reproduce delta and effect for test case', function () {
      expect(out.delta.total).to.be.closeTo(delta.total, 0.01);
      expect(out.effect.total).to.be.closeTo(effect.total, 0.01);
    });
  });
});
