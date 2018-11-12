<template>
  <v-card :max-height="maxHeight" style="overflow-y:auto;">
    <v-card-text>
      <h3>
        <span v-if="scenario.status === 'new'">New</span>
        <span v-else>Edit</span>
        Scenario (ID: {{ scenario.id }})
      </h3>
      <div>
        # Barriers Selected: <span v-if="scenario.barriers.length > 0">{{ scenario.barriers.length }}</span><span v-else>None</span>
      </div>
      <div style="max-height:125px;overflow-y:scroll;" class="mt-2" v-if="scenario.barriers.length > 0">
        <v-chip
          v-for="barrier in scenario.barriers"
          :key="barrier.id"
          small
          close
          @input="removeBarrier(barrier)">
          {{ barrier.id }}
        </v-chip>
      </div>
      <div class="grey--text text--darken-2 mt-3" v-else>
        <v-icon small>info</v-icon> Point and click on the map to select a barrier, or use the polygon/rectangle map tools to select multiple barriers.
      </div>
    </v-card-text>
    <v-card-actions class="pl-3 mb-2">
      <v-layout row wrap>
        <v-btn
          @click="createSingleScenario(scenario)"
          small
          :disabled="scenario.barriers.length === 0">
          <v-icon>play_arrow</v-icon> Run <span v-if="$vuetify.breakpoint.mdAndUp">&nbsp;Scenario</span>
        </v-btn>
        <v-btn
          @click="batch.show = true"
          small
          :disabled="scenario.barriers.length === 0">
          <v-icon>scatter_plot</v-icon>
          Create
          <span v-if="$vuetify.breakpoint.mdAndUp">&nbsp;Subset Scenarios</span>
          <span v-if="$vuetify.breakpoint.smAndDown">&nbsp;Subsets</span>
        </v-btn>
        <v-spacer></v-spacer>
        <v-btn
          @click="newScenario()"
          small
          :disabled="scenario.barriers.length === 0">
          <v-icon>clear</v-icon> Clear
        </v-btn>
      </v-layout>
    </v-card-actions>
    <v-card-text v-if="batch.show">
      <h3>Create Subset Scenarios</h3>
      <p class="caption lighten-1">
        To automatically generate multiple scenarios containing subsets for all combinations of barriers that are currently selected, choose the number of barriers to be included in each subset scenario and then click Run.
      </p>
      <v-alert
        :value="scenario.barriers.length >= batch.max"
        type="error"
        outline>
        Too many barriers selected, cannot be more than {{ batch.max }}.
      </v-alert>
      <v-alert
        :value="scenario.barriers.length < batch.min"
        type="error"
        outline>
        Too few barriers selected, must be at least {{ batch.min }}.
      </v-alert>
      <div
        v-if="(scenario.barriers.length <= batch.max) &&
              (scenario.barriers.length >= batch.min)">
        <p class="subheading">Number of Barriers in Each Scenario:</p>
        <v-radio-group v-model="batch.choose" row justify-right class="text-xs-center">
          <v-radio
            v-for="i in 5"
            :key="i"
            :label="i.toString()"
            :value="i"
            :disabled="i >= scenario.barriers.length">
          </v-radio>
        </v-radio-group>
        <div>
          # Scenarios: {{ this.nBatchScenarios }}
        </div>
      </div>
      <v-layout justify-left>
        <v-btn
          @click="createBatchScenarios(scenario)"
          small
          :disabled="!batch.choose"
          :loading="batch.loading"
          v-show="(scenario.barriers.length <= batch.max) &&
                  (scenario.barriers.length >= batch.min)">
          <v-icon>play_arrow</v-icon> Run Subset Scenarios
        </v-btn>
        <v-spacer></v-spacer>
        <v-btn @click="batch.show = false" small>
          <v-icon>cancel</v-icon> Cancel
        </v-btn>
      </v-layout>
    </v-card-text>
    <v-snackbar v-model="batch.snackbar.show" top :timeout="4000">
      {{ batch.snackbar.text }}
      <v-btn
        color="blue"
        flat
        @click="batch.snackbar.show = false">
        Close
      </v-btn>
    </v-snackbar>
    <v-divider></v-divider>
    <v-card-text>
      <h3>Scenarios List</h3>
      <v-data-table
        :headers="[
          {
            text: 'Status',
            value: 'status',
            sortable: false,
            align: 'center',
            width: '1%'
          },
          {
            text: 'ID',
            value: 'id',
            width: '1%'
          },
          {
            text: '# Barriers',
            value: 'barriers.length',
            align: 'right',
            width: '1%'
          },
          {
            text: 'Connectivity Gain',
            value: 'results.delta',
            align: 'right',
            width: '1%'
          },
          {
            text: 'Restoration Potential',
            value: 'results.effect',
            align: 'right',
            width: '1%'
          },
          {
            text: '',
            align: 'center',
            width: '1%'
          }
        ]"
        :items="scenarios"
        :loading="nScenariosTotal > 0"
        :pagination.sync="pagination"
        no-data-text="No scenarios have been created yet.">
        <v-progress-linear slot="progress" color="blue" v-model="percentScenariosComplete"></v-progress-linear>
        <template slot="items" slot-scope="props">
          <tr
            @click="selectRow(props.item)"
            style="cursor:pointer"
            :class="{ selected: (props.item.id === scenario.id) }">
            <td class="text-xs-center">
              <span v-if="props.item.status === 'finished'">
                <v-tooltip bottom>
                  <v-icon slot="activator" color="green">check_circle_outline</v-icon>
                  <span>Complete</span>
                </v-tooltip>
              </span>
              <span v-else-if="props.item.status === 'failed'">
                <v-tooltip bottom>
                  <v-icon slot="activator" color="red">highlight_off</v-icon>
                  <span>Failed</span>
                </v-tooltip>
              </span>
              <span v-else>
                <v-tooltip bottom>
                  <v-progress-circular
                    slot="activator"
                    indeterminate
                    color="primary">
                  </v-progress-circular>
                  <span>Calculating...</span>
                </v-tooltip>
              </span>
            </td>
            <td class="text-xs-center">{{ props.item.id }}</td>
            <td class="text-xs-right">
              {{ props.item.barriers.length }}
            </td>
            <td class="text-xs-right">
              <span v-if="props.item.results">
                {{ props.item.results.delta | number }}
              </span>
            </td>
            <td class="text-xs-right">
              <span v-if="props.item.results">
                {{ props.item.results.effect | number }}
              </span>
            </td>
            <td class="text-xs-right">
              <v-layout row justify-end>
                <v-tooltip bottom>
                  <v-icon
                    slot="activator"
                    @click.stop="deleteScenario(props.item)"
                    >delete
                  </v-icon>
                  <span>Delete Scenario</span>
                </v-tooltip>
              </v-layout>
            </td>
          </tr>
        </template>
      </v-data-table>
      <div>
        <strong>Status</strong>:
        <span v-if="nScenariosTotal === 0">No scenarios have been created</span>
        <span v-else-if="nScenariosRemaining > 0">Running scenarios ({{ percentScenariosComplete.toFixed(1)}}% complete, {{ nScenariosRemaining }} remaining)</span>
        <span v-else>All scenarios have finished running</span>
      </div>
    </v-card-text>
    <v-card-actions class="pa-3">
      <v-layout>
        <v-btn
          @click="downloadScenariosCsv"
          small
          :disabled="scenarios.length === 0 || nScenariosRemaining > 0">
          <v-icon>save_alt</v-icon> Download Scenarios
        </v-btn>
        <v-spacer></v-spacer>
        <v-btn
          @click="clearScenarios"
          small
          :disabled="scenarios.length === 0 || nScenariosRemaining > 0">
          <v-icon>delete</v-icon> Delete All
        </v-btn>
      </v-layout>
    </v-card-actions>
  </v-card>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import generatorics from 'generatorics';
import download from 'downloadjs';

import { number } from '@/filters';

const json2csv = require('json2csv');

export default {
  name: 'scenario-card',
  created() {
    this.newScenario();
  },
  filters: {
    number
  },
  data() {
    return {
      batch: {
        choose: null,
        max: 50,
        min: 2,
        show: false,
        loading: false,
        snackbar: {
          show: false,
          text: null
        }
      },
      pagination: {
        sortBy: 'results.effect',
        descending: true
      }
    };
  },
  computed: {
    ...mapGetters(['scenario', 'scenarios', 'project', 'region']),
    nScenariosTotal() {
      return this.scenarios.length;
    },
    nScenariosComplete() {
      return this.scenarios
        .filter(d => d.status === 'finished' || d.status === 'failed')
        .length;
    },
    nScenariosRemaining() {
      return this.nScenariosTotal - this.nScenariosComplete;
    },
    percentScenariosComplete() {
      return this.nScenariosTotal > 0 ? (this.nScenariosComplete / this.nScenariosTotal) * 100 : 100;
    },
    nBatchScenarios() {
      if (!this.batch.choose) {
        return 0;
      }
      const n = this.scenario.barriers.length;
      const k = this.batch.choose;
      return Math.round(generatorics.C(n, k));
    },
    maxHeight() {
      return this.$vuetify.breakpoint.mdAndUp ? this.$vuetify.breakpoint.height - 160 : Infinity;
    }
  },
  methods: {
    ...mapActions(['deleteScenario', 'newScenario', 'loadScenario', 'clearScenarios']),
    addBarrier(barrier) {
      this.scenario.barriers.push(barrier);
    },
    removeBarrier(barrier) {
      const index = this.scenario.barriers.findIndex(d => d === barrier);
      this.scenario.barriers.splice(index, 1);
    },
    selectRow(item) {
      if (this.scenario && this.scenario.id === item.id) {
        this.newScenario();
      } else {
        this.loadScenario(item);
      }
    },
    createSingleScenario(scenario) {
      if (!scenario || scenario.barriers.length === 0) {
        alert('No barriers selected');
        return null;
      }

      return this.newScenario(scenario.id)
        .then(() => this.$store.dispatch('runScenario', scenario));
    },
    createBatchScenarios(scenario) {
      if (!scenario || scenario.barriers.length === 0) {
        alert('No barriers selected');
        return null;
      }

      if (scenario.barriers.length <= this.batch.choose) {
        alert(`Need at least ${this.batch.choose + 1} barriers selected for batch mode`);
        return null;
      }

      this.batch.loading = true;

      const scenariosBarriers = [...generatorics.clone.combination(scenario.barriers, this.batch.choose)];
      const { id } = scenario;
      const scenarios = scenariosBarriers.map((s, i) => {
        const newScenario = {
          id: id + i,
          barriers: s,
          status: 'new'
        };
        return newScenario;
      });

      this.batch.snackbar.show = true;
      this.batch.snackbar.text = `Created ${scenarios.length} new scenarios, each with ${this.batch.choose} barrier(s)`;
      this.batch.choose = null;
      this.batch.show = false;

      this.newScenario(scenario.id + (scenarios.length - 1))
        .then(() => {
          const promises = scenarios.map(s => this.$store.dispatch('runScenario', s));
          this.batch.loading = false;
          return Promise.all(promises);
        });
    },
    downloadScenariosCsv() {
      if (this.scenarios.length > 0) {
        const project = [
          {
            label: 'name',
            value: this.project.name
          },
          {
            label: 'description',
            value: this.project.description
          },
          {
            label: 'author',
            value: this.project.author
          },
          {
            label: 'created',
            value: (new Date(this.project.created)).toLocaleString()
          }
        ];

        if (this.region.type === 'huc8') {
          project.push({
            label: 'region',
            value: `${this.region.feature.properties.name} (HUC8 ${this.region.feature.properties.huc8})`
          });
        } else {
          project.push({
            label: 'region',
            value: 'custom polygon'
          });
        }

        const scenarios = this.scenarios.map(d => { // eslint-disable-line
          return {
            id: d.id,
            n_barriers: d.barriers.length,
            connectivity_gain: d.results.delta,
            restoration_potential: d.results.effect
          };
        });

        const barriers = [];
        this.scenarios.forEach(s => { // eslint-disable-line
          s.barriers.forEach(b => {   // eslint-disable-line
            barriers.push({
              scenario_id: s.id,
              barrier_id: b.id,
              lat: b.lat,
              lon: b.lon,
              type: b.type,
              surveyed: b.surveyed,
              connectivity_gain: b.delta,
              restoration_potential: b.effect,
              aquatic_passability: b.aquatic
            });
          });
        });

        const projectCsv = json2csv.parse(project, { header: false });
        const scenariosCsv = json2csv.parse(scenarios, {});
        const barriersCsv = json2csv.parse(barriers, {});

        const csv = `# Project Info\n${projectCsv}\n\n# Scenarios List\n${scenariosCsv}\n\n# Barriers List\n${barriersCsv}`;

        download(csv, 'scenarios.csv', 'text/csv');
      } else {
        alert('No scenarios');
      }
    }
  }
};
</script>

<style>
table.v-table tbody td:first-child, table.v-table tbody td:not(:first-child), table.v-table tbody th:first-child, table.v-table tbody th:not(:first-child), table.v-table thead td:first-child, table.v-table thead td:not(:first-child), table.v-table thead th:first-child, table.v-table thead th:not(:first-child) {
  padding: 0 10px
}
tr.selected {
  background: #DDD;
}
</style>
