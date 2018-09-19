<template>
  <v-container>
    <v-layout row wrap>
      <!-- Left Column -->
      <v-flex xs12 xl3>
        <v-container fluid grid-list-lg>
          <v-layout column>
            <v-flex>
              <v-card v-if="project">
                <v-toolbar dark color="blue" card dense>
                  <v-toolbar-title>Project Info</v-toolbar-title>
                </v-toolbar>
                <v-card-text class="pb-4">
                  <v-layout row wrap>
                    <v-flex xs3 class="text-xs-right font-weight-medium">Project:</v-flex>
                    <v-flex xs9>{{project.name}}</v-flex>
                    <v-flex xs3 class="text-xs-right font-weight-medium">Description:</v-flex>
                    <v-flex xs9 class="text-truncate">{{project.description}}</v-flex>
                    <v-flex xs3 class="text-xs-right font-weight-medium">Author:</v-flex>
                    <v-flex xs9>{{project.author}}</v-flex>
                    <v-flex xs3 class="text-xs-right font-weight-medium">Region:</v-flex>
                    <v-flex xs9>{{region.type}}</v-flex>
                    <v-flex xs3 class="text-xs-right font-weight-medium"># Barriers:</v-flex>
                    <v-flex xs9>{{barriers.length | number}}</v-flex>
                  </v-layout>
                </v-card-text>
                <v-card-actions class="pb-4 pr-4">
                  <v-layout justify-end>
                    <v-btn to="/project/new" small>
                      <v-icon>control_point</v-icon> New
                    </v-btn>
                    <v-btn small>
                      <v-icon>create</v-icon> Edit
                    </v-btn>
                    <v-btn @click="downloadJson()" small>
                      <v-icon>file_download</v-icon> Export
                    </v-btn>
                  </v-layout>
                </v-card-actions>
              </v-card>
            </v-flex>
            <v-flex>
              <v-card>
                <v-toolbar dark color="blue" card dense>
                  <v-toolbar-title>Scenarios List</v-toolbar-title>
                </v-toolbar>
                <v-card-text>
                  <v-data-table
                    :headers="[
                      {
                        text: 'Status',
                        value: 'status',
                        sortable: false,
                        align: 'center'
                      },
                      {
                        text: 'ID',
                        value: 'id'
                      },
                      {
                        text: '# Barriers',
                        value: 'barriers.length',
                        align: 'right'
                      },
                      {
                        text: 'Delta',
                        value: 'results.delta.total',
                        align: 'right'
                      },
                      {
                        text: 'Effect',
                        value: 'results.effect.total',
                        align: 'right'
                      },
                      {
                        text: 'Actions',
                        align: 'center'
                      }
                    ]"
                    :items="scenarios"
                    hide-actions
                    class="elevation-1"
                    no-data-text="No scenarios have been created yet."
                  >
                    <template slot="items" slot-scope="props">
                      <td class="text-xs-center pl-5">
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
                          {{ props.item.results.delta.total | number }}
                        </span>
                      </td>
                      <td class="text-xs-right">
                        <span v-if="props.item.results">
                          {{ props.item.results.effect.total | number }}
                        </span>
                      </td>
                      <td class="text-xs-center pl-5">
                        <v-layout row>
                          <v-tooltip bottom>
                            <v-icon
                              slot="activator" @click="loadScenario(props.item)">edit
                            </v-icon>
                            <span>Edit Scenario</span>
                          </v-tooltip>
                          <v-tooltip bottom>
                            <v-icon
                              slot="activator" @click="deleteScenario(props.item)">delete
                            </v-icon>
                            <span>Delete Scenario</span>
                          </v-tooltip>
                        </v-layout>
                      </td>
                    </template>
                  </v-data-table>
                </v-card-text>
                <v-card-actions class="pb-4">
                  <v-layout justify-end class="pr-3">
                    <v-btn @click="clearScenarios()" small>
                      <v-icon>delete</v-icon> Delete All
                    </v-btn>
                  </v-layout>
                </v-card-actions>
              </v-card>
            </v-flex>
          </v-layout>
        </v-container>
      </v-flex>

      <!-- Middle Column -->
      <v-flex xs12 xl6>
        <v-container fluid grid-list-lg>
          <v-layout column>
            <v-flex>
              <v-card>
                <v-toolbar dark color="blue" card dense>
                  <v-toolbar-title>Map</v-toolbar-title>
                </v-toolbar>
                <v-card-text>
                  <barriers-map
                    :selected="scenario.barriers"
                    @add-barrier="addBarrierToScenario"
                    @remove-barrier="removeBarrierFromScenario">
                  </barriers-map>
                </v-card-text>
              </v-card>
            </v-flex>
          </v-layout>
        </v-container>
      </v-flex>

      <!-- Right Column -->
      <v-flex xs12 xl3>
        <v-container fluid grid-list-lg>
          <v-layout column>
            <v-flex>
              <v-card v-if="project">
                <v-toolbar dark color="blue" card dense>
                  <v-toolbar-title>Current Scenario</v-toolbar-title>
                </v-toolbar>
                <v-card-text>
                  id: {{ scenario.id }}<br>
                  status: {{ scenario.status }}<br>
                  # barriers selected: {{ scenario.barriers.length }}
                  <ul>
                    <li v-for="barrier in scenario.barriers" :key="barrier.id">
                      {{ barrier.id }}
                      (<a href="#" @click.prevent="removeBarrierFromScenario(barrier)">remove</a>)
                    </li>
                  </ul>
                </v-card-text>
                <v-card-actions class="px-4 pb-4">
                  <v-layout>
                    <v-btn
                      @click="createSingleScenario(scenario)"
                      small
                      :disabled="scenario.barriers.length === 0">
                      <v-icon>check</v-icon> Done
                    </v-btn>
                    <v-btn
                      @click="batch.show = true"
                      small
                      :disabled="scenario.barriers.length === 0">
                      <v-icon>scatter_plot</v-icon> Batch
                    </v-btn>
                    <v-spacer></v-spacer>
                    <v-btn
                      @click="newScenario()"
                      small
                      :disabled="scenario.barriers.length === 0">
                      <v-icon>cancel</v-icon> Clear
                    </v-btn>
                  </v-layout>
                </v-card-actions>
                <v-card-text v-if="batch.show">
                  <h2>Batch Scenario Tool</h2>
                  <p class="caption lighten-1">
                    Automatically generate multiple scenarios containing unique combinations of
                    barriers that are currently selected. First, choose the number of barriers to
                    be included in each scenario (must be less than the total number of selected
                    barriers) and then click Done.
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
                        v-for="i in 4"
                        :key="i"
                        :label="i.toString()"
                        :value="i"
                        :disabled="i >= scenario.barriers.length">
                      </v-radio>
                    </v-radio-group>
                  </div>
                  <v-layout justify-left>
                    <v-btn
                      @click="createBatchScenarios(scenario)"
                      small
                      :disabled="!batch.choose"
                      v-show="(scenario.barriers.length <= batch.max) &&
                              (scenario.barriers.length >= batch.min)">
                      <v-icon>check</v-icon> Done
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
              </v-card>
            </v-flex>
          </v-layout>
        </v-container>
      </v-flex>
    </v-layout>
  </v-container>
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
      batch: {
        choose: null,
        max: 20,
        min: 2,
        show: false,
        snackbar: {
          show: false,
          text: null
        }
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
    if (!this.project) {
      this.$router.push('/');
    }
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

      if (scenario.barriers.length <= this.batch.choose) {
        alert(`Need at least ${this.batch.choose + 1} barriers selected for batch mode`);
        return null;
      }

      const scenarios = [...generatorics.clone.combination(scenario.barriers, this.batch.choose)];
      const { id } = scenario;
      const promises = scenarios.map((s, i) => {
        const newScenario = {
          id: id + i,
          barriers: s,
          status: 'new'
        };
        return this.$store.dispatch('saveScenario', newScenario);
      });

      this.batch.snackbar.show = true;
      this.batch.snackbar.text = `Created ${promises.length} new scenarios, each with ${this.batch.choose} barrier(s)`;
      this.batch.choose = null;
      this.batch.show = false;

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
      const name = this.project.name || 'critical-linkages-scenario-builder';
      const filename = `${slugify(name, { lower: true })}.json`;

      download(JSON.stringify(data, null, 2), filename, 'application/json');
    }
  }
};
</script>
