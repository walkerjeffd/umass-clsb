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
    <v-container fluid fill-height grid-list-xs class="pa-2" v-if="$vuetify.breakpoint.mdAndUp || project">
      <v-layout row>
        <v-flex xs12 md6 lg5 xl4>
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
                <v-icon small class="mr-1">settings</v-icon> Map Settings
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
    <v-container fluid fill-height grid-list-xs class="pa-2" v-if="$vuetify.breakpoint.smAndDown && project">
      <div style="width:100%;height:400px">
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
      </div>
    </v-container>

    <!-- welcome dialog -->
    <v-dialog
      :fullscreen="$vuetify.breakpoint.mdAndDown"
      persistent
      scrollable
      v-model="dialog"
      max-width="1000">
      <v-card>
        <v-toolbar color="white">
          <h1 class="headline">Welcome to the Aquatic Connectivity Scenario Analysis Tool</h1>
        </v-toolbar>

        <v-card-text>
          <v-container class="pb-1">
            <v-layout row wrap>
              <v-flex xs12>
                <p class="body-2 mb-2">
                  This tool uses road-stream crossing data from the North Atlantic Aquatic Connectivity Collaborative (NAACC) and the UMass Critical Linkages assessment to allow users to create scenarios that involve combinations of crossing replacements and/or dam removals, and evaluate them for gains in aquatic connectivity and ecological restoration potential.
                </p>
                <div class="text-xs-center">
                  <v-btn
                    v-if="!readMore"
                    @click="readMore = true"
                    small
                    flat
                    class="ma-0 mb-1">
                    <v-icon>expand_more</v-icon> Read More
                  </v-btn>
                </div>
                <div v-if="readMore">
                  <p>
                    Information about road-stream crossings includes aquatic passability scores, based either on NAACC assessments (surveyed crossing) or a model created for the Critical Linkages assessment (modeled crossings). Aquatic passability scores for dams are based on dam height.
                  </p>
                  <p>
                    When scenarios are run, the results are computed and presented in arbitrary units (useful only for comparing scenarios) and expressed as Connectivity Gain and Restoration Potential. Connectivity Gain is based on an aquatic connectedness metric used for the Critical Linkages assessment using a resistant kernel approach for evaluating connectivity. Connectivity Gain is the change in aquatic connectedness resulting from all the changes (i.e. crossing replacements and/or dam removals) in your scenario.
                  </p>
                  <p>
                    Restoration Potential takes into account both the change in aquatic connectivity (Connectivity Gain) and habitat quality (as expressed by an Index of Ecological Integrity).
                  </p>
                  <p>
                    For more information on the NAACC visit: <a href="http://streamcontinuity.org">streamcontinuity.org</a>.
                  </p>
                  <p>
                    Follow these links for more information about:
                  </p>
                  <ul>
                    <li>
                      <a href="https://scholarworks.umass.edu/data/55/">Critical Linkages</a>
                    </li>
                    <li>
                      <a href="https://scholarworks.umass.edu/designing_sustainable_landscapes_techdocs/10/">Aquatic Connectedness</a>
                    </li>
                    <li>
                      <a href="https://scholarworks.umass.edu/designing_sustainable_landscapes_techdocs/8/">Index of Ecological Integrity</a>
                    </li>
                    <div class="text-xs-center">
                      <v-btn
                        @click="readMore = false"
                        small
                        flat>
                        <v-icon>expand_less</v-icon> Show Less
                      </v-btn>
                    </div>
                  </ul>
                </div>
              </v-flex>
            </v-layout>
          </v-container>
          <v-divider></v-divider>
          <v-container grid-list-xl>
            <v-layout row wrap>
              <v-flex xs12 md6>
                <v-hover>
                  <v-card
                    slot-scope="{ hover }"
                    :class="`elevation-${hover ? 12 : 2}`"
                    to="/project/new">
                    <v-toolbar dark color="blue">
                      <h3>Create New Project</h3>
                    </v-toolbar>
                    <v-card-text>Create a new project.</v-card-text>
                  </v-card>
                </v-hover>
              </v-flex>
              <v-flex xs12 md6>
                <v-hover>
                  <v-card
                    slot-scope="{ hover }"
                    :class="`elevation-${hover ? 12 : 2}`"
                    to="/project/load">
                    <v-toolbar dark color="blue">
                      <h3>Load Existing Project</h3>
                    </v-toolbar>
                    <v-card-text>Load an existing project from a previously exported text file.</v-card-text>
                  </v-card>
                </v-hover>
              </v-flex>
              <v-flex xs12 md6 v-if="hasLocalProject">
                <v-hover>
                  <v-card
                    slot-scope="{ hover }"
                    :class="`elevation-${hover ? 12 : 2}`"
                    @click.native="loadLocalProject" style="cursor:pointer">
                    <v-toolbar dark color="blue">
                      <h3>Resume Project</h3>
                    </v-toolbar>
                    <v-card-text>Pick up where you left off on your last project.</v-card-text>
                  </v-card>
                </v-hover>
              </v-flex>
              <v-flex xs12 md6>
                <v-hover>
                  <v-card
                    slot-scope="{ hover }"
                    :class="`elevation-${hover ? 12 : 2}`"
                    @click.native="loadDemoProject" style="cursor:pointer">
                    <v-toolbar dark color="blue">
                      <h3>Demo Project</h3>
                    </v-toolbar>
                    <v-card-text>Load the demo project.</v-card-text>
                  </v-card>
                </v-hover>
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
      readMore: false,
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
    loadDemoProject() {
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
