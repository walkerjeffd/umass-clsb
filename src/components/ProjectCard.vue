<template>
  <v-card>
    <v-card-text>
      <v-layout row wrap v-if="project">
        <v-flex xs3 class="text-xs-right font-weight-medium pr-3">Project:</v-flex>
        <v-flex xs9>{{project.name}}</v-flex>

        <v-flex xs3 class="text-xs-right font-weight-medium pr-3">Description:</v-flex>
        <v-flex xs9 class="text-truncate">
          {{project.description}}
          <span v-if="!project.description">None</span>
        </v-flex>

        <v-flex xs3 class="text-xs-right font-weight-medium pr-3">Author:</v-flex>
        <v-flex xs9>
          {{project.author}}
          <span v-if="!project.author">None</span>
        </v-flex>

        <v-flex xs3 class="text-xs-right font-weight-medium pr-3">Region:</v-flex>
        <v-flex xs9>
          <div v-if="region.type === 'huc8'">
            HUC8 Watershed ({{region.feature.properties.name}}, {{region.feature.properties.huc8}})
          </div>
          <div v-if="region.type === 'draw'">
            Custom polygon area ({{region.feature.properties.areaKm2 | number}} sq. km)
          </div>
        </v-flex>
      </v-layout>
    </v-card-text>
    <v-divider></v-divider>
    <v-card-actions class="pa-3">
      <v-layout row wrap>
        <v-flex xs12 lg4>
          <v-btn @click="dialog.export = true" small>
            <v-icon>file_download</v-icon> Save/Export Project
          </v-btn>
        </v-flex>
        <v-flex xs12 lg8 text-lg-right>
          <v-btn to="/project/new" small>
            <v-icon>add</v-icon> New Project
          </v-btn>
          <v-btn to="/project/load" small>
            <v-icon>publish</v-icon> Load Project
          </v-btn>
        </v-flex>
      </v-layout>
    </v-card-actions>
    <v-dialog
      v-model="dialog.export"
      max-width="400">
      <v-card>
        <v-card-title
          class="headline"
          primary-title>
          Export/Save Project
        </v-card-title>

        <v-card-text>
          <p>
            Click the button below to download your project as a text file. The file will be automatically saved to your browser's downloads folder.
          </p>
          <p>
            The project file can be re-loaded at a later time or on a different computer using the "Load Existing Project" option on the CLSB homepage.
          </p>
          <v-layout row justify-center>
            <v-btn @click="downloadJson()" color="blue" dark>
              <v-icon>file_download</v-icon> Download Project File
            </v-btn>
          </v-layout>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            flat
            @click="dialog.export = false">
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-card>
</template>

<script>
import { mapGetters } from 'vuex';
import download from 'downloadjs';
import slugify from 'slugify';

import { VERSION } from '@/constants';
import { number } from '@/filters';

export default {
  name: 'project-card',
  data() {
    return {
      dialog: {
        export: false
      }
    };
  },
  computed: {
    ...mapGetters(['project', 'region', 'barriers', 'scenarios'])
  },
  filters: {
    number
  },
  methods: {
    downloadJson() {
      const data = {
        version: VERSION,
        project: this.project,
        region: this.region,
        barriers: this.barriers,
        scenarios: this.scenarios
      };
      const name = this.project.name || 'aquatic-connectivity-scenario-project';
      const filename = `${slugify(name, { lower: true })}.json`;

      download(JSON.stringify(data, null, 2), filename, 'application/json');

      this.dialog.export = false;
    }
  }
};
</script>

<style scoped>
</style>
