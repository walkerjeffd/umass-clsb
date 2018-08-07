import Vue from 'vue';
import Vuex from 'vuex';

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    project: null,
    scenarios: [],
    barriers: []
  },
  getters: {
    project: state => state.project,
    scenarios: state => state.scenarios,
    barriers: state => state.barriers
  },
  mutations: {
    SET_PROJECT(state, project) {
      state.project = project;
    },
    SET_BARRIERS(state, barriers) {
      state.barriers = barriers;
    }
  },
  actions: {
    createProject({ commit }, project) {
      commit('SET_PROJECT', project);
    },
    setBarriers({ commit }, barriers) {
      commit('SET_BARRIERS', barriers);
    }
  },
});
