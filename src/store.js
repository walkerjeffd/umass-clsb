import Vue from 'vue';
import Vuex from 'vuex';
import axios from 'axios';

import { VERSION, LOCALSTORAGE_PROJECT_KEY, BATCH_CHUNK_SIZE } from '@/constants';
import { validateProject } from '@/validation';

const graph = require('../lib/graph/');

let exceedsLocalStorage = false;

Vue.use(Vuex);

function cloneScenario(d) {
  return {
    id: d.id,
    barriers: d.barriers.map(b => b),
    status: d.status
  };
}

const store = new Vuex.Store({
  state: {
    version: VERSION,
    project: null,
    region: null,
    barriers: [],
    scenario: {
      barriers: [],
      status: 'new'
    },
    scenarios: []
  },
  getters: {
    project: state => state.project,
    region: state => state.region,
    barriers: state => state.barriers,
    scenarios: state => state.scenarios,
    scenario: state => state.scenario
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
    SET_SCENARIOS(state, scenarios) {
      state.scenarios = scenarios;
    },
    CREATE_SCENARIO(state, scenario) {
      state.scenarios.push(scenario);
    },
    UPDATE_SCENARIO(state, scenario) {
      const index = state.scenarios.findIndex(d => d.id === scenario.id);
      if (index >= 0) {
        Vue.set(state.scenarios, index, scenario);
      } else {
        throw new Error(`Scenario not found (id = ${scenario.id})`);
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
    createProject({ commit }, { project, region, barriers }) {
      commit('SET_PROJECT', project);
      commit('SET_REGION', region);
      commit('SET_BARRIERS', barriers);
      commit('SET_SCENARIOS', []);
      return Promise.resolve();
    },
    loadProject({ commit, dispatch }, payload) {
      if (!payload) {
        return Promise.reject(new Error('Unable to read file or it is empty'));
      }

      validateProject(payload)
        .then(() => {
          commit('SET_PROJECT', payload.project);
          commit('SET_BARRIERS', payload.barriers);
          commit('SET_REGION', payload.region);
          commit('SET_SCENARIOS', payload.scenarios);
          return dispatch('newScenario');
        });
    },
    clearScenarios({ commit, dispatch }) {
      console.log('store:clearScenarios');
      return dispatch('newScenario')
        .then(() => commit('SET_SCENARIOS', []));
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
    deleteScenario({ commit, state, dispatch }, scenario) {
      if (state.scenario.id === scenario.id) {
        dispatch('newScenario');
      }
      commit('DELETE_SCENARIO', scenario);
    },
    newScenario({ commit }) {
      const scenario = {
        barriers: [],
        status: 'new'
      };

      commit('SET_SCENARIO', scenario);
    },
    loadScenario({ commit }, scenario) {
      commit('SET_SCENARIO', cloneScenario(scenario));
    },
    createScenario({ commit, state }, scenario) {
      let id = 1;
      if (state.scenarios.length > 0) {
        id = Math.max(...state.scenarios.map(d => d.id)) + 1;
      }
      scenario.id = id;
      commit('CREATE_SCENARIO', scenario);
      return Promise.resolve(scenario);
    },
    updateScenario({ commit, state }, scenario) {
      const index = state.scenarios.findIndex(d => d.id === scenario.id);
      if (index >= 0) {
        if (scenario.results) {
          delete scenario.results;
        }
        scenario.status = 'new';

        // Vue.set(state.scenarios, index, scenario);
        commit('UPDATE_SCENARIO', scenario);
        return Promise.resolve(scenario);
      }
      return Promise.reject(new Error(`Scenario not found (id=${scenario.id})`));
    },
    runScenario({ commit }, scenario) {
      const barrierIds = scenario.barriers.map(d => d.id);

      scenario.status = 'fetching';
      return axios.post('/network', { barrierIds })
        .then(response => response.data.data)
        .then((network) => {
          const { targets } = network;
          scenario.status = 'calculating';
          commit('UPDATE_SCENARIO', scenario);

          setTimeout(() => {
            const { nodes, edges } = graph.trim(targets, network.nodes, network.edges);
            const results = graph.linkages(targets, nodes, edges);

            scenario.results = {
              delta: results.delta.total,
              effect: results.effect.total
            };

            scenario.status = 'finished';
            commit('UPDATE_SCENARIO', scenario);
          }, 100);
        })
        .catch((err) => {
          // alert('Error: Unable to calculate effect for selected barrier ids');
          console.error(err);
          scenario.status = 'failed';
          commit('UPDATE_SCENARIO', scenario);
        });
    },
    runScenarios({ dispatch }, scenarios) {
      // run all scenarios in serial using parallel chunks
      const chunks = [];
      while (scenarios.length > 0) {
        chunks.push(scenarios.splice(0, BATCH_CHUNK_SIZE));
      }

      // https://decembersoft.com/posts/promises-in-serial-with-array-reduce/
      return chunks.reduce((promises, chunkScenarios) => { // eslint-disable-line arrow-body-style
        return promises.then((chainResults) => {
          const chunkPromises = chunkScenarios
            .map(s => dispatch('runScenario', s));
          return Promise.all(chunkPromises)
            .then(currentResult => [...chainResults, ...currentResult]);
        });
      }, Promise.resolve([]));
    }
  }
});

store.subscribe((mutation, state) => {
  if (mutation.type === 'CREATE_SCENARIO') {
    // skip localStorage update when saving new scenario
    return;
  }

  if (mutation.type === 'UPDATE_SCENARIO' &&
      mutation.payload.status !== 'updated' &&
      mutation.payload.status !== 'finished' &&
      mutation.payload.status !== 'failed') {
    // skip localStorage update if updating a scenario that has not finished or failed
    return;
  }

  if (exceedsLocalStorage || !state.project) {
    return;
  }

  const data = {
    version: state.version,
    project: state.project,
    region: state.region,
    barriers: state.barriers,
    scenarios: state.scenarios
      .filter(d => d.status === 'failed' || d.status === 'finished')
  };

  try {
    localStorage.setItem(LOCALSTORAGE_PROJECT_KEY, JSON.stringify(data));
  } catch (e) {
    exceedsLocalStorage = true;
    alert('Warning! The current project cannot be auto-saved in your browser because it exceeds the maximum allowable size.\n\nYou may continue to build new scenarios. However, you must export the project using the Export/Save button on the Project tab or the Download button on the Scenarios tab to avoid losing your work.');
  }
});

export default store;
