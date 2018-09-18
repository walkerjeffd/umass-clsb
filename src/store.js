import Vue from 'vue';
import Vuex from 'vuex';
import axios from 'axios';

const graph = require('../lib/graph/');

Vue.use(Vuex);

function cloneScenario(d) {
  return {
    id: d.id,
    barriers: d.barriers.map(b => b),
    status: d.status
  };
}

export default new Vuex.Store({
  state: {
    project: null,
    region: null,
    barriers: [],
    scenario: null,
    scenarios: []
  },
  getters: {
    project: state => state.project,
    region: state => state.region,
    barriers: state => state.barriers,
    scenario: state => state.scenario,
    scenarios: state => state.scenarios
  },
  mutations: {
    SET_PROJECT(state, project) {
      state.project = project;
    },
    SET_REGION(state, region) {
      state.region = region;
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
    setProject({ commit }, project) {
      commit('SET_PROJECT', project);
    },
    setRegion({ commit }, region) {
      return axios.post('/barriers/geojson', {
        feature: region.feature
      }).then((response) => {
        const barriers = response.data.data;
        commit('SET_REGION', region);
        commit('SET_BARRIERS', barriers);
      });
    },
    setBarriers({ commit }, barriers) {
      commit('SET_BARRIERS', barriers);
    },
    deleteScenario({ commit }, scenario) {
      commit('DELETE_SCENARIO', scenario);
    },
    newScenario({ commit, state }, lastId) {
      lastId = lastId || 0;
      const id = Math.max(...state.scenarios.map(d => d.id), lastId) + 1;

      const scenario = {
        id,
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
      return axios.post('/network', { barrierIds })
        .then(response => response.data.data)
        .then((network) => {
          const { targets } = network;
          scenario.status = 'calculating';
          commit('SAVE_SCENARIO', scenario);

          setTimeout(() => {
            scenario.network = graph.trim(targets, network.nodes, network.edges);
            const { nodes, edges } = scenario.network;
            scenario.results = graph.linkages(targets, nodes, edges);

            scenario.status = 'finished';
            commit('SAVE_SCENARIO', scenario);
          }, 2000);
        })
        .catch((err) => {
          alert('Error: Unable to calculate effect for selected barrier ids');
          console.error(err);
          scenario.status = 'failed';
          commit('SAVE_SCENARIO', scenario);
        });
    }
  }
});
