import Vue from 'vue';
import Vuex from 'vuex';
import axios from 'axios';

const graph = require('../lib/graph/');

Vue.use(Vuex);

function cloneScenario(d) {
  return {
    id: d.id,
    barriers: d.barriers.map(b => b),
    status: 'new'
  };
}

export default new Vuex.Store({
  state: {
    project: null,
    barriers: [],
    scenario: {
      id: null,
      barriers: [],
      status: 'new'
    },
    scenarios: [],
    scenarioIdSeq: 1
  },
  getters: {
    project: state => state.project,
    scenario: state => state.scenario,
    scenarios: state => state.scenarios,
    barriers: state => state.barriers,
    scenarioIdSeq: state => state.scenarioIdSeq
  },
  mutations: {
    SET_PROJECT(state, project) {
      state.project = project;
    },
    SET_BARRIERS(state, barriers) {
      state.barriers = barriers;
    },
    SET_SCENARIO(state, scenario) {
      state.scenario = scenario;
    },
    SAVE_SCENARIO(state, scenario) {
      const index = state.scenarios.findIndex(d => d.id === scenario.id);
      if (index >= 0) {
        state.scenarios[index] = scenario;
      } else {
        state.scenarios.push(scenario);
        state.scenarioIdSeq += 1;
      }
    },
    DELETE_SCENARIO(state, scenario) {
      const index = state.scenarios.findIndex(d => d.id === scenario.id);
      if (index >= 0) {
        state.scenarios.splice(index, 1);
      } else {
        throw new Error(`Scenario not found (id = ${scenario.id})`);
      }
    }
  },
  actions: {
    createProject({ commit }, project) {
      commit('SET_PROJECT', project);
    },
    setBarriers({ commit }, barriers) {
      commit('SET_BARRIERS', barriers);
    },
    deleteScenario({ commit }, scenario) {
      commit('DELETE_SCENARIO', scenario);
    },
    newScenario({ commit, state }) {
      const scenario = {
        id: state.scenarioIdSeq,
        barriers: [],
        status: 'new'
      };

      commit('SET_SCENARIO', scenario);
    },
    loadScenario({ commit }, scenario) {
      commit('SET_SCENARIO', cloneScenario(scenario));
    },
    saveScenario({ commit }, scenario) {
      const barrierIds = scenario.barriers.map(d => d.id);

      scenario.status = 'fetching';
      commit('SAVE_SCENARIO', scenario);
      axios.post('/network', {
        barrierIds
      }).then(response => response.data.data)
        .then((network) => {
          const { targets } = network;

          scenario.status = 'calculating';
          commit('SAVE_SCENARIO', scenario);
          scenario.network = graph.trim(targets, network.nodes, network.edges);
          const { nodes, edges } = scenario.network;
          scenario.results = graph.linkages(targets, nodes, edges);

          scenario.status = 'finished';
          commit('SAVE_SCENARIO', scenario);
        });
    }
  }
});
