import Vue from 'vue';
import Router from 'vue-router';

Vue.use(Router);

export default new Router({
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('./views/Home.vue'),
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
  ],
});
