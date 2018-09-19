<template>
  <v-container>
    <v-layout align-center justify-center>
      <v-flex xs12 lg8 xl6>
        <h1 class="pb-4">Load Project</h1>
        <v-stepper v-model="step">
          <v-stepper-header>
            <v-stepper-step :complete="step > 1" step="1">Load File</v-stepper-step>
            <v-divider></v-divider>
            <v-stepper-step step="2">Review</v-stepper-step>
          </v-stepper-header>

          <v-stepper-items>
            <v-stepper-content step="1">
              <div class="mb-2">
                <upload-button title="Select Project File" @input="setFile"></upload-button>

                <div class="pl-2 pt-3">
                  <div v-if="file">
                    <strong>File Selected</strong>: {{ file.name }}
                  </div>
                  <div v-else>
                    Click the button above and select the project file previously exporter from the
                    scenario builder interface. Then click Next to load the project.
                  </div>
                </div>
              </div>
              <v-layout justify-end>
                <v-btn
                  color="primary"
                  @click="nextStep"
                  :disabled="!file"
                  :loading="status === 'loading'">
                  Next <v-icon>chevron_right</v-icon>
                </v-btn>
              </v-layout>
            </v-stepper-content>

            <v-stepper-content step="2">
              <div class="mb-2">
                <v-alert :value="status === 'loaded'" type="success" outline>
                  File successfully loaded. Click Next to proceed to the Scenario Builder.
                </v-alert>
                <v-alert :value="status === 'error'" type="error" outline>
                  Failed to load file <br/>
                  {{ error.toString() }}
                </v-alert>
              </div>
              <v-layout justify-spacing-between>
                <v-btn flat @click="step = 1">
                  <v-icon>chevron_left</v-icon> Prev
                </v-btn>
                <v-spacer></v-spacer>
                <v-btn
                  color="primary"
                  to="/builder">
                  Next <v-icon>chevron_right</v-icon>
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

import UploadButton from '@/components/UploadButton.vue';

export default {
  name: 'project-load',
  components: {
    UploadButton
  },
  data() {
    return {
      step: 1,
      file: null,
      status: 'ready',
      error: ''
    };
  },
  methods: {
    ...mapActions(['loadProjectFile']),
    nextStep() {
      if (this.step === 1) {
        this.status = 'loading';

        return setTimeout(() => this.loadFile(this.file)
          .then(() => {
            this.status = 'loaded';
            this.step += 1;
          })
          .catch((err) => {
            this.error = err;
            this.status = 'error';
            this.step += 1;
          }), 2000);
      }
      return null;
    },
    prevStep() {
      if (this.step === 1) return;
      this.step -= 1;
    },
    setFile(file) {
      this.file = file;
    },
    loadFile(file) {
      const reader = new FileReader();

      return new Promise((resolve, reject) => {
        if (!file) {
          return reject(new Error('No file selected'));
        }

        reader.onload = (e) => {
          let json;
          try {
            json = JSON.parse(e.target.result);
          } catch (err) {
            console.error(err);
            return reject(err);
          }

          return this.loadProjectFile(json)
            .then(() => {
              return resolve(json);
            })
            .catch((err) => {
              console.error(err);
              return reject(err);
            });
        };

        reader.readAsText(this.file);
      });
    }
  }
};
</script>

<style>

</style>
