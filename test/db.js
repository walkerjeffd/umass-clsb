/* eslint-env mocha */
/* eslint-disable func-names, prefer-arrow-callback, no-unused-expressions */

const chai = require('chai');

const db = require('../api/db');
const dataGraphTrimSingle = require('./data/graph-trim-single');
const dataGraphTrimMultiple = require('./data/graph-trim-multiple');

const expect = chai.expect; // eslint-disable-line

describe('db', function () {
  describe('#getBarriers()', function () {
    describe('single target', function () {
      const barrierIds = dataGraphTrimSingle.targets.map(d => d.id);

      it('should return an array', function () {
        return db.getBarriers(barrierIds)
          .then((barriers) => {
            expect(barriers).to.be.an('array').that.has.lengthOf(barrierIds.length);
          });
      });

      it('should return barriers with correct format', function () {
        return db.getBarriers(barrierIds)
          .then((barriers) => {
            const barrier = barriers[0];
            expect(barrier).to.be.an('object').that.has.all.keys('id', 'x_coord', 'y_coord', 'effect', 'effect_ln', 'delta', 'type', 'lat', 'lon', 'node_id', 'aquatic', 'surveyed');
            expect(barrier.id).to.be.a('string');
            expect(barrier.x_coord).to.be.a('number');
            expect(barrier.y_coord).to.be.a('number');
            expect(barrier.effect).to.be.a('number');
            expect(barrier.effect_ln).to.be.a('number');
            expect(barrier.delta).to.be.a('number');
            expect(barrier.type).to.be.oneOf(['crossing', 'dam']);
            expect(barrier.lat).to.be.a('number');
            expect(barrier.lon).to.be.a('number');
            expect(barrier.node_id).to.be.a('string');
          });
      });
    });

    describe('multiple targets', function () {
      const barrierIds = dataGraphTrimMultiple.targets.map(d => d.id);

      it('should return an array', function () {
        return db.getBarriers(barrierIds)
          .then((barriers) => {
            expect(barriers).to.be.an('array').that.has.lengthOf(barrierIds.length);
          });
      });

      it('should return barriers with correct format', function () {
        return db.getBarriers(barrierIds)
          .then((barriers) => {
            const barrier = barriers[0];
            expect(barrier).to.be.an('object').that.has.all.keys('id', 'x_coord', 'y_coord', 'effect', 'effect_ln', 'delta', 'type', 'lat', 'lon', 'node_id', 'aquatic', 'surveyed');
            expect(barrier.id).to.be.a('string');
            expect(barrier.x_coord).to.be.a('number');
            expect(barrier.y_coord).to.be.a('number');
            expect(barrier.effect).to.be.a('number');
            expect(barrier.effect_ln).to.be.a('number');
            expect(barrier.delta).to.be.a('number');
            expect(barrier.type).to.be.oneOf(['crossing', 'dam']);
            expect(barrier.lat).to.be.a('number');
            expect(barrier.lon).to.be.a('number');
            expect(barrier.node_id).to.be.a('string');
          });
      });
    });
  });

  describe('#getNetwork()', function () {
    describe('single target', function () {
      const barrierIds = dataGraphTrimSingle.targets.map(d => d.id);

      it('should have length one', function () {
        expect(barrierIds).to.have.lengthOf(1);
      });

      it('should return object with targets, nodes and edges', function () {
        return db.getNetwork(barrierIds)
          .then((network) => {
            expect(network).to.be.an('object').that.has.all.keys('nodes', 'edges', 'targets');
            expect(network.nodes).to.not.be.empty;
            expect(network.edges).to.not.be.empty;
          });
      });

      it('should return nodes with correct format', function () {
        return db.getNetwork(barrierIds)
          .then((network) => {
            const node = network.nodes[0];
            expect(node).to.be.an('object').that.has.all.keys('node_id', 'x', 'y', 'cost');
            expect(node.node_id).to.be.a('string');
            expect(node.x).to.be.a('number');
            expect(node.y).to.be.a('number');
            expect(node.cost).to.be.a('number');
          });
      });

      it('should return edges with correct format', function () {
        return db.getNetwork(barrierIds)
          .then((network) => {
            const edge = network.edges[0];
            expect(edge).to.be.an('object').that.has.all.keys('id', 'start_id', 'end_id', 'length', 'cost', 'value');
            expect(edge.id).to.be.a('number');
            expect(edge.start_id).to.be.a('string');
            expect(edge.end_id).to.be.a('string');
            expect(edge.length).to.be.a('number');
            expect(edge.cost).to.be.a('number');
            expect(edge.value).to.be.a('number');
          });
      });
    });
  });
});
