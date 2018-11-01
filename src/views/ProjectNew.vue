<template>
  <v-container>
    <v-layout align-center justify-center>
      <v-flex xs12 lg8 xl6>
        <h1 class="pb-4">New Project</h1>
        <v-stepper v-model="step">
          <v-stepper-header>
            <v-stepper-step :complete="step > 1" step="1">Project Information</v-stepper-step>
            <v-divider></v-divider>
            <v-stepper-step :complete="step > 2" step="2">Define Region</v-stepper-step>
            <v-divider></v-divider>
            <v-stepper-step step="3">Review</v-stepper-step>
          </v-stepper-header>

          <v-stepper-items>
            <v-stepper-content step="1">
              <v-form
                ref="info"
                @keyup.native.enter="nextStep"
                v-model="info.valid">
                <div class="mb-5">
                  <v-container>
                    <v-layout row wrap>
                      <v-flex xs12>
                        <v-text-field
                          label="Project Name (required)"
                          v-model="info.name"
                          :rules="info.rules.name"
                          required
                        ></v-text-field>
                      </v-flex>
                      <v-flex xs12>
                        <v-text-field
                          label="Description"
                          v-model="info.description"
                        ></v-text-field>
                      </v-flex>
                      <v-flex xs12>
                        <v-text-field
                          label="Author"
                          v-model="info.author"
                        ></v-text-field>
                      </v-flex>
                    </v-layout>
                  </v-container>
                </div>
                <v-layout justify-end>
                  <v-btn
                    color="primary"
                    @click="nextStep">
                    Next <v-icon>chevron_right</v-icon>
                  </v-btn>
                </v-layout>
              </v-form>
            </v-stepper-content>

            <v-stepper-content step="2">
              <div class="mb-3">
                <v-select
                  :items="region.types"
                  label="Select Region Type"
                  v-model="region.type">
                </v-select>
                <div v-if="step === 2">
                  <region-map
                    :type="region.type" :feature="region.feature" @loadRegion="loadRegion">
                  </region-map>
                </div>
                <v-alert
                  :value="!!region.error"
                  type="error"
                  class="mt-4">
                  {{ region.error }}
                </v-alert>
              </div>
              <v-layout justify-spacing-between>
                <v-btn flat @click="step = 1">
                  <v-icon>chevron_left</v-icon> Prev
                </v-btn>
                <v-spacer></v-spacer>
                <v-btn
                  color="primary"
                  @click="nextStep"
                  :loading="region.loading">
                  Next <v-icon>chevron_right</v-icon>
                </v-btn>
              </v-layout>
            </v-stepper-content>

            <v-stepper-content step="3">
              <p>Please review your project and then click Finish to begin creating new scenarios.</p>

              <v-layout row wrap>
                <v-flex md8>
                  <v-data-table
                    :headers="[
                      {
                        width: '1%'
                      }
                    ]"
                    :items="reviewItems"
                    hide-actions
                    hide-headers>
                    <template slot="items" slot-scope="props">
                      <td class="text-xs-right">{{ props.item.label }}</td>
                      <td class="text-xs-left">{{ props.item.value }}</td>
                    </template>
                  </v-data-table>
                </v-flex>
              </v-layout>

              <p class="mt-4">
                <strong>Note:</strong> These project settings cannot be changed after you click Finish.
              </p>


              <v-layout justify-spacing-between>
                <v-btn flat @click="step = 2">
                  <v-icon>chevron_left</v-icon> Prev
                </v-btn>
                <v-spacer></v-spacer>
                <v-btn color="primary" @click="submit" :loading="creatingProject">
                  Finish
                </v-btn>
              </v-layout>
            </v-stepper-content>
          </v-stepper-items>
        </v-stepper>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script>
import { mapActions } from 'vuex';
import axios from 'axios';

import RegionMap from '@/components/RegionMap.vue';
import { DRAW_MAX_AREA_KM2, VERSION } from '@/constants';
import { number } from '@/filters';

export default {
  name: 'project-new',
  components: { RegionMap },
  filters: { number },
  data() {
    return {
      step: 1,
      info: {
        valid: true,
        name: '',
        description: '',
        author: '',
        rules: {
          name: [v => !!v || 'Project name is required']
        }
      },
      region: {
        type: 'huc8',
        feature: null,
        error: '',
        loading: false,
        types: [
          {
            text: 'Watershed (HUC8)',
            value: 'huc8'
          },
          {
            text: 'Draw Polygon',
            value: 'draw'
          }
        ]
      },
      barriers: [],
      creatingProject: false
    };
  },
  computed: {
    reviewItems() {
      const info = [
        {
          label: 'Name',
          value: this.info.name
        },
        {
          label: 'Description',
          value: this.info.description
        },
        {
          label: 'Author',
          value: this.info.author
        }
      ];

      const region = {
        label: 'Region',
        value: 'None'
      };
      if (this.region.feature) {
        if (this.region.type === 'huc8') {
          region.value = `HUC8 Watershed (${this.region.feature.properties.name}, ${this.region.feature.properties.huc8})`;
        }
        if (this.region.type === 'draw') {
          region.value = `Custom polygon area (${number(this.region.feature.properties.areaKm2)} sq. km)`;
        }
      }

      const barriers = {
        label: '# Barriers',
        value: 'None'
      };
      if (this.barriers.length > 0) {
        barriers.value = `${number(this.barriers.length)}`;
      }
      return [
        ...info,
        region,
        barriers
      ];
    }
  },
  methods: {
    ...mapActions(['createProject', 'setRegion']),
    nextStep() {
      if (this.step === 1) {
        if (this.validateInfo()) {
          this.step += 1;
        }
      } else if (this.step === 2) {
        if (this.validateRegion()) {
          this.region.loading = true;
          return this.fetchBarriers(this.region.feature)
            .then((barriers) => {
              this.region.loading = false;
              this.barriers = barriers;

              if (this.barriers.length === 0) {
                if (this.region.type === 'huc8') {
                  this.region.error = 'Selected watershed does not contain any barriers. Try a different watershed.';
                } else if (this.region.type === 'draw') {
                  this.region.error = 'Selected region does not contain any barriers. Make sure the area is entirely within the project boundaries, or try drawing a different area.';
                }
              } else {
                this.step += 1;
              }
            })
            .catch((err) => {
              this.region.loading = false;
              console.log(err);
              this.region.error = 'Server Error: Failed to retrieve barriers from the server.';
            });
        }
      }

      return null;
    },
    prevStep() {
      if (this.step === 1) return;
      this.step -= 1;
    },
    validateInfo() {
      return this.$refs.info.validate();
    },
    validateRegion() {
      if (!this.region.feature) {
        if (this.region.type === 'huc8') {
          this.region.error = 'Select a watershed to continue';
        } else if (this.region.type === 'draw') {
          this.region.error = 'Use the rectangle or polygon tool to draw a region';
        }
        return false;
      }

      if (this.region.type === 'draw') {
        const { areaKm2 } = this.region.feature.properties;
        if (areaKm2 > DRAW_MAX_AREA_KM2) {
          this.region.error = `The selected region has an area of ${number(areaKm2)} sq. km, which exceeds the maximum allowed area (${number(DRAW_MAX_AREA_KM2)} sq. km). Please draw a smaller area.`;
          return false;
        }
      }

      this.region.error = '';
      return true;
    },
    loadRegion(feature) {
      this.region.feature = feature;
      this.region.error = '';
      this.barriers = [];
    },
    fetchBarriers(feature) {
      return axios.post('/barriers/geojson', {
        feature
      }).then(response => response.data.data);
    },
    submit() {
      const project = {
        name: this.info.name,
        description: this.info.description,
        author: this.info.author,
        created: (new Date()).valueOf(),
        version: VERSION
      };
      const region = {
        type: this.region.type,
        feature: this.region.feature
      };
      const barriers = this.barriers;

      const payload = {
        project,
        region,
        barriers
      };

      this.creatingProject = true;
      return this.createProject(payload)
        .then(() => {
          this.creatingProject = false;
          this.$router.push('/builder');
        })
        .catch((err) => {
          this.creatingProject = false;
          console.log(err);
          alert('Failed to create project. Error printed to console log.');
        });
    }
  }
};
</script>
