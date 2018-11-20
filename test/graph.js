/* eslint-env mocha */
/* eslint-disable func-names, prefer-arrow-callback, no-unused-expressions */

const chai = require('chai');
const jStat = require('jStat');
const graph = require('../lib/graph/');

const dataEffectsSingle = require('./data/graph-effects-single');
const dataTrimSingle = require('./data/graph-trim-single');
const dataTrimMultiple = require('./data/graph-trim-multiple');

const expect = chai.expect; // eslint-disable-line

describe('graph', function () {
  describe('#data-effects', function () {
    describe('single target', function () {
      it('should have targets, network, and output', function () {
        expect(dataEffectsSingle).to.be.an('object').that.has.all.keys('targets', 'network', 'output');
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
        expect(out.nodes.map(d => d.node_id)).to.deep.equal(output.nodes.map(d => d.node_id));
      });

      it('should return same edges as R', function () {
        expect(out.edges).to.have.lengthOf(output.edges.length);
        expect(out.edges.map(d => d.start_id)).to.deep.equal(output.edges.map(d => d.start_id));
        expect(out.edges.map(d => d.end_id)).to.deep.equal(output.edges.map(d => d.end_id));
      });
    });
    describe('multiple targets', function () {
      const { input, output, targets } = dataTrimMultiple;
      const out = graph.trim(targets, input.nodes, input.edges);

      it('should return object with nodes and edges', function () {
        expect(out).to.be.an('object').that.has.all.keys('nodes', 'edges');
      });

      it('should return same nodes as R', function () {
        expect(out.nodes).to.have.lengthOf(output.nodes.length);
        expect(out.nodes.map(d => d.node_id)).to.deep.equal(output.nodes.map(d => d.node_id));
      });

      it('should return same edges as R', function () {
        expect(out.edges).to.have.lengthOf(output.edges.length).and.not.be.empty;
        expect(out.edges.map(d => d.start_id)).to.deep.equal(output.edges.map(d => d.start_id));
        expect(out.edges.map(d => d.end_id)).to.deep.equal(output.edges.map(d => d.end_id));
      });
    });
  });

  describe('#kernel()', function () {
    const {
      targets, network, output
    } = dataEffectsSingle;

    const targetNodeIds = targets.map(d => d.node_id);

    const { nodes, edges } = network;
    const { kernels } = output;

    const base = graph.kernel(targets, nodes, edges, nodes.map(d => d.cost));
    const alt = graph.kernel(targets, nodes, edges, nodes.map(d =>
      (targetNodeIds.includes(d.node_id) ? 0 : d.cost)));

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
      targets, network, output
    } = dataEffectsSingle;

    const { nodes, edges } = network;
    const { delta, effect } = output;

    const out = graph.linkages(targets, nodes, edges);
    it('should return object', function () {
      expect(out).to.be.a('object').that.has.all.keys('delta', 'effect', 'kernels');
      expect(out.delta).to.be.an('object').that.has.all.keys('total', 'values');
      expect(out.effect).to.be.an('object').that.has.all.keys('total', 'values');
      expect(out.kernels).to.be.an('object').that.has.all.keys('base', 'alt');
    });
    it('should reproduce delta and effect for test case', function () {
      expect(out.delta.total).to.be.closeTo(delta.total, 0.01);
      expect(out.effect.total).to.be.closeTo(effect.total, 0.01);
    });
  });

  describe('hva scenarios', function () {
    describe('hva scenario id=2', function () {
      const {
        targets, network, output
      } = require('./data/hva-scenario-2.json');

      const { nodes, edges } = network;
      const { delta, effect } = output;

      const out = graph.linkages(targets, nodes, edges);
      it('should reproduce delta and effect for test case', function () {
        expect(out.delta.total).to.be.closeTo(delta.total, 0.01);
        expect(out.effect.total).to.be.closeTo(effect.total, 0.01);
      });
    });
    describe('hva scenario id=3', function () {
      const {
        targets, network, output
      } = require('./data/hva-scenario-3.json');

      const { nodes, edges } = network;
      const { delta, effect } = output;

      const out = graph.linkages(targets, nodes, edges);
      it('should reproduce delta and effect for test case', function () {
        expect(out.delta.total).to.be.closeTo(delta.total, 0.01);
        expect(out.effect.total).to.be.closeTo(effect.total, 0.01);
      });
    });
    describe('hva scenario id=60', function () {
      const {
        targets, network, output
      } = require('./data/hva-scenario-60.json');

      const { nodes, edges } = network;
      const { delta, effect } = output;

      const out = graph.linkages(targets, nodes, edges);
      it('should reproduce delta and effect for test case', function () {
        expect(out.delta.total).to.be.closeTo(delta.total, 0.01);
        expect(out.effect.total).to.be.closeTo(effect.total, 0.01);
      });
    });
  });
});
