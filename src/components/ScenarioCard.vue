<template>
  <v-card>
    <v-card-text>
      <h4>New Scenario</h4>
      <span>ID: {{ scenario.id }}</span>
      <div>
        Selected Barriers:
        <v-chip
          v-for="barrier in scenario.barriers"
          :key="barrier.id"
          small
          close
          @input="removeBarrier(barrier)">
          {{ barrier.id }}
        </v-chip>
        <span v-if="scenario.barriers.length === 0">None</span>
      </div>
    </v-card-text>
    <v-card-actions class="pl-3">
      <v-layout>
        <v-btn
          @click="createSingleScenario(scenario)"
          small
          :disabled="scenario.barriers.length === 0">
          <v-icon>save_alt</v-icon> Save
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
          <v-icon>sync</v-icon> Restart
        </v-btn>
      </v-layout>
    </v-card-actions>
    <v-card-text v-if="batch.show">
      <h4>Batch Scenario Tool</h4>
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
    <v-divider></v-divider>
    <v-card-text>
      <h4>Scenarios List</h4>
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
            text: 'Effect',
            value: 'results.effect.total',
            align: 'right'
          },
          {
            text: '',
            align: 'center'
          }
        ]"
        :items="scenarios"
        no-data-text="No scenarios have been created yet.">
        <template slot="items" slot-scope="props">
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
              {{ props.item.results.effect.total | number }}
            </span>
          </td>
          <td class="text-xs-right">
            <v-layout row justify-end>
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
  </v-card>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import generatorics from 'generatorics';

import { number } from '@/filters';

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
  computed: {
    ...mapGetters(['scenario', 'scenarios'])
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
    }
  }
};
</script>

<style scoped>

</style>
