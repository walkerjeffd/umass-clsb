<template>
  <div>
    <!-- map on md-xl devices -->
    <v-layout class="map-container" v-if="$vuetify.breakpoint.mdAndUp">
      <barriers-map
        :region="region"
        :barriers="barriers"
        :selected="scenario.barriers"
        :variable="variable"
        :color-scale="colorScale"
        :variable-scale="variableScale"
        :highlight="highlight"
        @add-barrier="addBarrier"
        @remove-barrier="removeBarrier">
      </barriers-map>
    </v-layout>

    <!-- tab box -->
    <v-container fluid fill-height grid-list-xs class="pa-2">
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
                  <v-card-text class="py-3" v-show="!hideVariable">
                    <v-select
                      v-model="variable"
                      :items="variables"
                      item-text="label"
                      item-value="id"
                      label="Select Color Variable"
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
                    <v-layout row wrap>
                      <div class="subheading grey--text text--darken-3 mt-3 mb-0">Highlight Barrier Types</div>
                      <v-flex xs12 class="ml-3">
                        <v-switch
                          v-model="highlight.surveyed"
                          color="#FF8F00"
                          label="Surveyed Crossings"
                          hide-details>
                        </v-switch>
                        <v-switch
                          v-model="highlight.dams"
                          color="#D500FF"
                          label="Dams"
                          hide-details>
                        </v-switch>
                      </v-flex>
                    </v-layout>
                  </v-card-text>
                </v-card>
              </v-tab-item>
            </v-tabs>
          </v-card>
        </v-flex>
      </v-layout>
    </v-container>

    <!-- map on xs-sm devices -->
    <v-container fluid fill-height grid-list-xs class="pa-2" v-if="$vuetify.breakpoint.smAndDown">
      <div style="width:100%;height:400px">
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
    </v-container>
    <v-dialog
      persistent
      v-model="dialog"
      width="800">
      <v-card>
        <v-toolbar color="primary" dark>
          <h1>Welcome to the Aquatic Connectivity Scenario Analysis Tool</h1>
        </v-toolbar>

        <v-card-text>
          <v-container grid-list-xl>
            <v-layout row wrap>
              <v-flex xs12 md6 v-if="hasLocalProject">
                <v-card>
                  <v-toolbar dark color="blue">
                    <h3>Resume Project</h3>
                  </v-toolbar>
                  <v-card-text>Pick up where you left off last time.</v-card-text>
                  <v-card-actions>
                    <v-btn flat @click="loadLocalProject">
                      Resume Project <v-icon>arrow_forward</v-icon>
                    </v-btn>
                  </v-card-actions>
                </v-card>
              </v-flex>
              <v-flex xs12 md6>
                <v-card>
                  <v-toolbar dark color="blue">
                    <h3>Demo Project</h3>
                  </v-toolbar>
                  <v-card-text>Load the demo project (this will be removed)</v-card-text>
                  <v-card-actions>
                    <v-btn flat @click="loadDevProject">
                      Load Demo <v-icon>arrow_forward</v-icon>
                    </v-btn>
                  </v-card-actions>
                </v-card>
              </v-flex>
              <v-flex xs12 md6>
                <v-card>
                  <v-toolbar dark color="blue">
                    <h3>Create New Project</h3>
                  </v-toolbar>
                  <v-card-text>Create a new project.</v-card-text>
                  <v-card-actions>
                    <v-btn flat to="/project/new">
                      Create Project <v-icon>arrow_forward</v-icon>
                    </v-btn>
                  </v-card-actions>
                </v-card>
              </v-flex>
              <v-flex xs12 md6>
                <v-card>
                  <v-toolbar dark color="blue">
                    <h3>Load Existing Project</h3>
                  </v-toolbar>
                  <v-card-text>Load an existing project from a text file.</v-card-text>
                  <v-card-actions>
                    <v-btn flat to="/project/load">
                      Load Project <v-icon>arrow_forward</v-icon>
                    </v-btn>
                  </v-card-actions>
                </v-card>
              </v-flex>
            </v-layout>
          </v-container>
        </v-card-text>
      </v-card>
    </v-dialog>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex';

import { VARIABLES, LOCALSTORAGE_PROJECT_KEY } from '@/constants';
import { validateProject } from '@/validation';
import * as errors from '@/errors';

import BarriersMap from '@/components/BarriersMap.vue';
import ProjectCard from '@/components/ProjectCard.vue';
import ScenarioCard from '@/components/ScenarioCard.vue';
import MapLegend from '@/components/MapLegend.vue';

import colorMixin from '@/mixins/color';
import variableMixin from '@/mixins/variable';

export default {
  name: 'home',
  mixins: [variableMixin, colorMixin],
  data() {
    return {
      hasLocalProject: false,
      dialog: false,
      show: true,
      hideCards: false,
      hideVariable: false,
      active: 1,
      variable: {},
      variables: VARIABLES,
      variableScale: null,
      colorScale: null,
      showLegend: false,
      showSurveyed: false,
      highlight: {
        surveyed: false,
        dams: false
      }
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
  beforeCreate() {

  },
  created() {
    this.setVariableById('effect');

    const localProjectString = localStorage.getItem(LOCALSTORAGE_PROJECT_KEY);

    if (localProjectString) {
      let project = null;
      try {
        project = JSON.parse(localProjectString);
      } catch (e) {
        console.log('localStorage project failed to parse, will be cleared');
        console.error(e);
        localStorage.removeItem(LOCALSTORAGE_PROJECT_KEY);
        return;
      }

      validateProject(project)
        .then(() => {
          this.hasLocalProject = true;
        })
        .catch(() => {
          localStorage.removeItem(LOCALSTORAGE_PROJECT_KEY);
        });
    }
  },
  mounted() {
    if (!this.project) {
      this.dialog = true;
    } else {
      window.barriers = this.barriers;
    }
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
    ...mapActions(['loadProject']),
    loadDevProject() {
      this.loadProject(require('@/data/project.json')); // eslint-disable-line
      this.dialog = false;
    },
    loadLocalProject() {
      const localProjectString = localStorage.getItem(LOCALSTORAGE_PROJECT_KEY);

      if (localProjectString) {
        let project = null;
        try {
          project = JSON.parse(localProjectString);
        } catch (e) {
          console.log('failed to load local project');
          console.error(e);
          localStorage.removeItem(LOCALSTORAGE_PROJECT_KEY);
          return;
        }

        return this.loadProject(project)
          .then(() => {
            this.hasLocalProject = true;
            this.dialog = false;
          })
          .catch(() => {
            localStorage.removeItem(LOCALSTORAGE_PROJECT_KEY);
          });
      }
    },
    setScales() {
      this.variableScale = this.getVariableScale(this.variable, this.barriers);
      this.colorScale = this.getColorScale(this.variable);
    },
    addBarrier(barrier) {
      this.scenario.barriers.push(barrier);
    },
    removeBarrier(barrier) {
      const index = this.scenario.barriers.findIndex(d => d.id === barrier.id);
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
