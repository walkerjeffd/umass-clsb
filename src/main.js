import '@babel/polyfill';
import axios from 'axios';
import Vue from 'vue';
import './plugins/vuetify';
import App from './App.vue';
import router from './router';
import store from './store';
import config from './config';

Vue.config.productionTip = false;

axios.defaults.baseURL = config[process.env.NODE_ENV].api.url;

new Vue({
  router,
  store,
  render: h => h(App),
}).$mount('#app');
