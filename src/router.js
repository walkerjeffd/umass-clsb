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
    },
    {
      path: '/dev/map',
      name: 'dev-map',
      component: () => import('./dev/Map.vue')
    },
    {
      path: '/dev/crossfilter-map',
      name: 'dev-crossfilter-map',
      component: () => import('./dev/CrossfilterMap.vue')
    },
    {
      path: '/dev/crossfilter-dc',
      name: 'dev-crossfilter-dc',
      component: () => import('./dev/CrossfilterDc.vue')
    },
    {
      path: '/dev/map-full',
      name: 'dev-map-full',
      component: () => import('./dev/MapFull.vue')
    },
    {
      path: '/dev/map-full-tabs',
      name: 'dev-map-full-tabs',
      component: () => import('./dev/MapFullTabs.vue')
    }
  ],
});
