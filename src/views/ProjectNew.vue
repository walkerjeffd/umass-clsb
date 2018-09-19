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
              <div class="mb-5">
                <v-form>
                  <v-container>
                    <v-layout row wrap>
                      <v-flex xs12>
                        <v-text-field
                          label="Project Name*"
                          v-model="form.name"
                        ></v-text-field>
                      </v-flex>
                      <v-flex xs12>
                        <v-text-field
                          label="Description"
                          v-model="form.description"
                        ></v-text-field>
                      </v-flex>
                      <v-flex xs12>
                        <v-text-field
                          label="Author"
                          v-model="form.author"
                        ></v-text-field>
                      </v-flex>
                    </v-layout>
                  </v-container>
                </v-form>
              </div>
              <v-btn
                color="primary"
                @click="nextStep">
                Next <v-icon>chevron_right</v-icon>
              </v-btn>
            </v-stepper-content>

            <v-stepper-content step="2">
              <div class="mb-5">
                <v-select
                  :items="regionTypes"
                  label="Select Region Type"
                  v-model="region.type">
                </v-select>
                <div v-if="step === 2">
                  <region-map
                    :type="region.type" :feature="region.feature" @loadRegion="loadRegion">
                  </region-map>
                </div>
              </div>
              <v-btn flat @click="step = 1">
                <v-icon>chevron_left</v-icon> Prev
              </v-btn>
              <v-btn
                color="primary"
                @click="nextStep">
                Next <v-icon>chevron_right</v-icon>
              </v-btn>
            </v-stepper-content>

            <v-stepper-content step="3">
              <p>You have selected {{ barriers.length }} barriers.</p>

              <ul>
                <li>Project Name: {{ form.name }}</li>
                <li>Description: {{ form.description }}</li>
                <li>Author: {{ form.author }}</li>
                <li>Region: {{ region.type }}</li>
              </ul>

              <v-btn flat @click="step = 2">
                <v-icon>chevron_left</v-icon> Prev
              </v-btn>

              <v-btn color="primary" @click="submit">
                Finish
              </v-btn>
            </v-stepper-content>
          </v-stepper-items>
        </v-stepper>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';

import RegionMap from '@/components/RegionMap.vue';

export default {
  name: 'project-new',
  components: { RegionMap },
  data() {
    return {
      step: 1,
      form: {
        name: '',
        description: '',
        author: ''
      },
      region: {
        type: 'huc8',
        feature: null
      },
      regionTypes: [
        {
          text: 'Watershed (HUC8)',
          value: 'huc8'
        },
        {
          text: 'Draw Polygon',
          value: 'draw'
        }
      ]
    };
  },
  computed: {
    ...mapGetters(['barriers'])
  },
  methods: {
    ...mapActions(['setProject', 'setRegion']),
    nextStep() {
      if (this.step === 1) {
        return this.setProject({
          name: this.form.name,
          description: this.form.description,
          author: this.form.author,
          created: (new Date()).valueOf()
        }).then(() => {
          this.step += 1;
        });
      } else if (this.step === 2) {
        if (!this.region.feature) {
          alert('No region selected');
          return null;
        }

        return this.setRegion(this.region)
          .then(() => {
            this.step += 1;
          });
      }

      return null;
    },
    prevStep() {
      if (this.step === 1) return;
      this.step -= 1;
    },
    loadRegion(feature) {
      this.region.feature = feature;
    },
    submit() {
      this.$router.push('/builder');
    }
  }
};
</script>
