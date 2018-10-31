<template>
  <v-card>
    <v-card-text>
      <v-layout row wrap>
        <v-flex xs3 class="text-xs-right font-weight-medium">Project:</v-flex>
        <v-flex xs9>{{project.name}}</v-flex>

        <v-flex xs3 class="text-xs-right font-weight-medium">Description:</v-flex>
        <v-flex xs9 class="text-truncate">
          {{project.description}}
          <span v-if="!project.description">None</span>
        </v-flex>

        <v-flex xs3 class="text-xs-right font-weight-medium">Author:</v-flex>
        <v-flex xs9>
          {{project.author}}
          <span v-if="!project.author">None</span>
        </v-flex>

        <v-flex xs3 class="text-xs-right font-weight-medium">Region:</v-flex>
        <v-flex xs9>
          <div v-if="region.type === 'huc8'">
            {{region.feature.properties.name}}
            (HUC8 {{region.feature.properties.huc8}})
          </div>
          <div v-else>Custom Polygon</div>
        </v-flex>
      </v-layout>
    </v-card-text>
    <v-divider></v-divider>
    <v-card-actions class="pa-3">
      <v-layout justify-space-between>
        <v-btn @click="downloadJson()" small>
          <v-icon>file_download</v-icon> Save/Export
        </v-btn>
        <v-spacer></v-spacer>
        <v-btn to="/project/new" small>
          <v-icon>control_point</v-icon> New Project
        </v-btn>
      </v-layout>
    </v-card-actions>
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
      const name = this.project.name || 'critical-linkages-scenario-builder';
      const filename = `${slugify(name, { lower: true })}.json`;

      download(JSON.stringify(data, null, 2), filename, 'application/json');
    }
  }
};
</script>

<style scoped>
</style>
