import Vue from 'vue';
import Router from 'vue-router';

import Home from './views/Home.vue';

Vue.use(Router);

export default new Router({
  routes: [
    {
      path: '/',
      name: 'home',
      component: Home,
    },
    {
      path: '/project',
      name: 'project',
      component: () => import('./views/Project.vue'),
      children: [
        {
          path: 'new',
          component: () => import('./views/ProjectNew.vue'),
        },
        {
          path: 'load',
          component: () => import('./views/ProjectLoad.vue'),
        }
      ]
    },
    {
      path: '/builder',
      name: 'builder',
      component: () => import('./views/Builder.vue')
    }
  ],
});
