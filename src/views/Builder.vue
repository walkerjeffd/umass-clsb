<template>
  <v-container fluid fill-height grid-list-xs class="pa-2">
    <div class="map-container">
      <barriers-map
        :region="region"
        :barriers="barriers"
        :selected="scenario.barriers"
        :variable="variable"
        :color-scale="colorScale"
        :variable-scale="variableScale"
        :show-surveyed="showSurveyed"
        @add-barrier="addBarrier"
        @remove-barrier="removeBarrier">
      </barriers-map>
    </div>
    <v-layout row>
      <v-flex xs12 md6 lg4>
        <v-card>
          <v-tabs
            v-model="active"
            color="blue"
            dark
            slider-color="white"
            @input="onTab">
            <v-tab
              ripple>
              <v-icon small class="mr-1">assignment</v-icon> Project
            </v-tab>
            <v-tab
              ripple>
              <v-icon small class="mr-1">scatter_plot</v-icon> Scenarios
            </v-tab>
            <v-tab
              ripple>
              <v-icon small class="mr-1">map</v-icon> Map Settings
            </v-tab>
            <v-spacer></v-spacer>
            <v-btn small outline dark @click="hideCards = !hideCards" class="mt-2 hide">
              <v-icon v-if="!hideCards">keyboard_arrow_up</v-icon>
              <v-icon v-else>keyboard_arrow_down</v-icon>
            </v-btn>
            <v-tab-item>
              <project-card v-show="!hideCards"></project-card>
            </v-tab-item>
            <v-tab-item>
              <scenario-card v-show="!hideCards"></scenario-card>
            </v-tab-item>
            <v-tab-item>
              <v-card v-show="!hideCards">
                <v-card-text class="py-2" v-show="!hideVariable">
                  <v-select
                    v-model="variable"
                    :items="variables"
                    item-text="label"
                    item-value="id"
                    label="Select Variable"
                    return-object>
                  </v-select>
                  <map-legend
                    :id="'a'"
                    :height="20"
                    :width="400"
                    :margins="{left: 10, right:10}"
                    :data="barriers"
                    :variable="variable"
                    :show="showLegend">
                  </map-legend>
                  <v-divider></v-divider>
                  <v-checkbox
                    v-model="showSurveyed">
                    <template slot="label">
                      Highlight Surveyed Culverts
                      <svg width="32" height="32"><circle r="10" cx="16" cy="16" fill="none" stroke="#FF8F00" stroke-width="2px"></circle></svg>
                    </template>
                  </v-checkbox>
                </v-card-text>
              </v-card>
            </v-tab-item>
          </v-tabs>
        </v-card>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script>
import { mapActions, mapGetters } from 'vuex';

import { VARIABLES } from '@/constants';

import BarriersMap from '@/components/BarriersMap.vue';
import ProjectCard from '@/components/ProjectCard.vue';
import ScenarioCard from '@/components/ScenarioCard.vue';
import MapLegend from '@/components/MapLegend.vue';

import colorMixin from '@/mixins/color';
import variableMixin from '@/mixins/variable';

import data from '../dev/data/project.json';

export default {
  name: 'builder',
  mixins: [variableMixin, colorMixin],
  data() {
    return {
      show: true,
      hideCards: false,
      hideVariable: false,
      active: 1,
      variable: {},
      variables: VARIABLES,
      variableScale: null,
      colorScale: null,
      showLegend: false,
      showSurveyed: false
    };
  },
  components: {
    BarriersMap,
    ProjectCard,
    ScenarioCard,
    MapLegend
  },
  computed: {
    ...mapGetters(['project', 'barriers', 'scenario', 'scenarios', 'region'])
  },
  created() {
    if (!this.project) {
      this.loadProjectFile(data);
    }
    this.setVariableById('effect');
  },
  watch: {
    variable() {
      this.setScales();
    },
    barriers() {
      this.setScales();
    }
  },
  methods: {
    ...mapActions(['loadProjectFile']),
    setScales() {
      this.variableScale = this.getVariableScale(this.variable, this.barriers);
      this.colorScale = this.getColorScale(this.variable);
    },
    addBarrier(barrier) {
      this.scenario.barriers.push(barrier);
    },
    removeBarrier(barrier) {
      const index = this.scenario.barriers.findIndex(d => d === barrier);
      this.scenario.barriers.splice(index, 1);
    },
    setVariableById(id) {
      const index = this.variables.findIndex(d => d.id === id);
      this.variable = this.variables[index];
    },
    onTab(tab) {
      if (tab === 3) {
        this.showLegend = true;
      } else {
        this.showLegend = false;
      }
    }
  }
};
</script>

<style>
.map-container {
  background: red;
  position: absolute;
  width: 100%;
  height: 100%;
  left: 0;
  top: 0;
}
.v-btn.hide {
  min-width: 0;
}
</style>
