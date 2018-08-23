<template>
  <div>
    <h2>Scenario Builder</h2>
    <div v-if="project">
      Current Project: {{ project.name }}
      <div v-if="barriers">
        There are {{ barriers.length }} barriers in the project region.
      </div>
      <barriers-map
        :selected="scenario.barriers"
        @add-barrier="addBarrierToScenario"
        @remove-barrier="removeBarrierFromScenario">
      </barriers-map>
      <div>
        <h4>Current Scenario</h4>
        <div>
          id: {{ scenario.id }}<br>
          # barriers selected: {{ scenario.barriers.length }}
          <ul>
            <li v-for="barrier in scenario.barriers" :key="barrier.id">
              {{ barrier.id }}
              (<a href="#" @click.prevent="removeBarrierFromScenario(barrier)">remove</a>)
            </li>
          </ul>
        </div>
        <div>
          <button @click="saveScenario(scenario)">Save Scenario</button>
          <button @click="removeAllBarriersFromScenario()">Remove All</button>
        </div>
      </div>
      <hr>
      <div>
        <h4>All Scenarios</h4>
        <div>
          <ul>
            <li v-for="scenario in scenarios" :key="scenario.id">
              {{ scenario.id }}
              (# barriers = {{ scenario.barriers.length }})
              (<a href="#" @click.prevent="loadScenario(scenario)">load</a>)
              (<a href="#" @click.prevent="deleteScenario(scenario)">delete</a>)
            </li>
          </ul>
        </div>
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

import BarriersMap from '@/components/BarriersMap.vue';

export default {
  data() {
    return {
      scenario: {
        id: 1,
        barriers: []
      },
      scenarios: [],
      seqId: 1
    };
  },
  components: {
    BarriersMap
  },
  computed: {
    ...mapGetters(['project', 'barriers'])
  },
  methods: {
    newScenario() {
      this.scenario.id = this.seqId;
      this.scenario.barriers = [];
    },
    addBarrierToScenario(barrier) {
      this.scenario.barriers.push(barrier);
    },
    removeBarrierFromScenario(barrier) {
      const index = this.scenario.barriers.findIndex(d => d === barrier);
      this.scenario.barriers.splice(index, 1);
    },
    removeAllBarriersFromScenario() {
      this.scenario.barriers.splice(0, this.scenario.barriers.length);
    },
    saveScenario(scenario) {
      const index = this.scenarios.findIndex(d => d.id === scenario.id);

      if (index >= 0) {
        // update existing
        this.scenarios[index].barriers = scenario.barriers.map(d => d);
      } else {
        // create new
        this.scenarios.push({
          id: scenario.id,
          barriers: scenario.barriers.map(d => d)
        });
        this.seqId = this.seqId + 1;
      }

      // start next scenario
      this.newScenario();
    },
    loadScenario(scenario) {
      this.scenario.id = scenario.id;
      this.scenario.barriers = scenario.barriers.map(d => d);
    },
    deleteScenario(scenario) {
      const index = this.scenarios.findIndex(d => d === scenario);
      this.scenarios.splice(index, 1);
    }
  }
};
</script>
