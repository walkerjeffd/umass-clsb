<template>
  <div>
    <h2>Scenario Builder</h2>
    <div v-if="project">
      <div>
        Current Project: {{ project.name }}
        (<a href="#" @click.prevent="downloadJson()">export project to file</a>)
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
          <button @click="createSingleScenario(scenario)">Save Single Scenario</button>
          <button @click="createBatchScenarios(scenario)">Create Multiple Scenarios</button>
          <button @click="newScenario()">Cancel/Clear</button>
        </div>
      </div>
      <hr>
      <div>
        <h4>All Scenarios</h4>
        <div v-if="scenarios.length === 0">No scenarios exist, create a new one.</div>
        <div v-else>
          <div>(<a href="#" @click.prevent="clearScenarios()">delete all</a>)</div>
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
import generatorics from 'generatorics';

import { VERSION } from '@/constants';
import { number } from '@/filters';
import BarriersMap from '@/components/BarriersMap.vue';

export default {
  data() {
    return {
      multi: {
        max: 10,
        choose: 2
      }
    };
  },
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
    ...mapActions(['deleteScenario', 'newScenario', 'loadScenario', 'clearScenarios']),
    addBarrierToScenario(barrier) {
      this.scenario.barriers.push(barrier);
    },
    removeBarrierFromScenario(barrier) {
      const index = this.scenario.barriers.findIndex(d => d === barrier);
      this.scenario.barriers.splice(index, 1);
    },
    createSingleScenario(scenario) {
      if (!scenario || scenario.barriers.length === 0) {
        alert('No barriers selected');
        return null;
      }

      return this.newScenario(scenario.id)
        .then(() => this.$store.dispatch('saveScenario', scenario));
    },
    createBatchScenarios(scenario) {
      if (!scenario || scenario.barriers.length === 0) {
        alert('No barriers selected');
        return null;
      }

      if (scenario.barriers.length <= this.multi.choose) {
        alert(`Need at least ${this.multi.choose + 1} barriers selected for multi mode`);
        return null;
      }

      const scenarios = [...generatorics.clone.combination(scenario.barriers, this.multi.choose)];
      const { id } = scenario;
      const promises = scenarios.map((s, i) => {
        const newScenario = {
          id: id + i,
          barriers: s,
          status: 'new'
        };
        return this.$store.dispatch('saveScenario', newScenario);
      });

      return this.newScenario(scenario.id + (promises.length - 1))
        .then(() => Promise.all(promises));
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
