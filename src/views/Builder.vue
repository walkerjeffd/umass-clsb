<template>
  <div>
    <h2>Scenario Builder</h2>
    <div v-if="project">
      <div>
        Current Project: {{ project.name }} (<a href="#" @click.prevent="downloadJson()">export</a>)
      </div>
      <div v-if="barriers">
        There are {{ barriers.length }} barriers in the project region.
      </div>
      <barriers-map
        :selected="scenario.barriers"
        @add-barrier="addBarrierToScenario"
        @remove-barrier="removeBarrierFromScenario">
      </barriers-map>
      <div>
        <h4>
          <span v-if="scenario.status === 'new'">New</span>
          <span v-if="scenario.status !== 'new'">Edit</span>
          Scenario
        </h4>
        <div>
          id: {{ scenario.id }}<br>
          status: {{ scenario.status }}<br>
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
          <button @click="newScenario()">Cancel/Clear</button>
        </div>
      </div>
      <hr>
      <div>
        <h4>All Scenarios</h4>
        <div>
          <ul>
            <li v-for="s in scenarios" :key="s.id">
              Scenario ID: {{ s.id }} <br/>
              # Barriers = {{ s.barriers.length }} <br/>
              Status = {{ s.status }}<br/>
              <span v-if="s.results">
                Delta = {{ s.results.delta.total | number }}<br/>
                Effect = {{ s.results.effect.total | number }}<br/>
              </span>
              (<a href="#" @click.prevent="loadScenario(s)">load</a>)
              (<a href="#" @click.prevent="deleteScenario(s)">delete</a>)
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
import { mapGetters, mapActions } from 'vuex';

import download from 'downloadjs';
import slugify from 'slugify';

import { VERSION } from '@/constants';
import { number } from '@/filters';
import BarriersMap from '@/components/BarriersMap.vue';

export default {
  components: {
    BarriersMap
  },
  computed: {
    ...mapGetters(['project', 'barriers', 'scenario', 'scenarios', 'region'])
  },
  filters: {
    number
  },
  created() {
    this.newScenario();
  },
  methods: {
    ...mapActions(['deleteScenario', 'newScenario', 'loadScenario']),
    addBarrierToScenario(barrier) {
      this.scenario.barriers.push(barrier);
    },
    removeBarrierFromScenario(barrier) {
      const index = this.scenario.barriers.findIndex(d => d === barrier);
      this.scenario.barriers.splice(index, 1);
    },
    saveScenario(scenario) {
      this.newScenario(scenario.id)
        .then(() => this.$store.dispatch('saveScenario', scenario));
    },
    downloadJson() {
      const data = {
        version: VERSION,
        project: this.project,
        region: this.region,
        barriers: this.barriers,
        scenarios: this.scenarios
      };
      const filename = `${slugify(this.project.name, { lower: true })}.json`;

      download(JSON.stringify(data, null, 2), filename, 'application/json');
    }
  }
};
</script>
