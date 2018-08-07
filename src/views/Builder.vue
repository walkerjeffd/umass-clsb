<template>
  <div>
    <h2>Scenario Builder</h2>
    <div v-if="project">
      Current Project: {{ project.name }}
      <div v-if="barriers">
        You have {{ barriers.length }} barriers selected.
      </div>
    </div>
    <div v-else>
      <router-link to="/project/new">Create New Project</router-link> or
      <router-link to="/project/load">Load Existing Project</router-link>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters(['project', 'barriers'])
  }
};
</script>
