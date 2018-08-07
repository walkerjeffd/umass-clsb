<template>
  <div>
    <h2>New Project</h2>
    <p>
      Want to load an existing project?
      <router-link to="/project/load">Go here instead</router-link>
    </p>
    <div v-if="step === 1">
      <h3>Step 1: Project Information</h3>
      <div>
        ID*: <input type="text" v-model="form.id">
      </div>
      <div>
        Name*: <input type="text" v-model="form.name">
      </div>
      <div>
        Description: <input type="text" v-model="form.description">
      </div>
      <div>
        Author: <input type="text" v-model="form.author">
      </div>
      <button @click="prevStep">Prev</button>
      <button @click="nextStep">Next</button>
    </div>
    <div v-if="step === 2">
      <h3>Step 2: Select Geographic Region</h3>
      <p>Select geographic region by:</p>
      <select v-model="region.type">
        <option disabled value="">Please select one</option>
        <option value="town">Town</option>
        <option value="huc8">HUC8 Watershed</option>
        <option value="draw">Draw Polygon</option>
      </select>

      <region-map :type="region.type" :feature="region.feature" @loadRegion="loadRegion">
      </region-map>
      <p>You have loaded {{ barriers.length }} barriers.</p>
      <button @click="prevStep">Prev</button>
      <button @click="nextStep">Next</button>
    </div>
    <div v-if="step === 3">
      <h3>Step 3: Submit Form</h3>
      <p>You have selected {{ barriers.length }} barriers.</p>
      <button @click="prevStep">Prev</button>
      <button @click="submit">Create Project</button>
    </div>
    <hr>
    <h3>Debug</h3>
<pre>
id: {{form.id}}
name: {{form.name}}
description: {{form.description}}
author: {{form.author}}
region.type: {{region.type}}
region.feature: {{region.feature}}
</pre>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import axios from 'axios';

import RegionMap from '@/components/RegionMap.vue';

export default {
  name: 'project-new',
  components: { RegionMap },
  data() {
    return {
      step: 1,
      form: {
        id: '',
        name: '',
        description: '',
        author: ''
      },
      region: {
        type: '',
        feature: null
      }
    };
  },
  computed: {
    ...mapGetters(['barriers'])
  },
  methods: {
    ...mapActions(['createProject', 'setBarriers']),
    nextStep() {
      if (this.step < 3) {
        this.step += 1;
      }
    },
    prevStep() {
      if (this.step > 1) {
        this.step -= 1;
      }
    },
    loadRegion(feature) {
      axios.post('/barriers/geojson', {
        feature
      }).then((response) => {
        const barriers = response.data.data;
        this.region.feature = feature;
        return this.setBarriers(barriers);
      });
    },
    submit() {
      this.createProject({
        id: this.form.id,
        name: this.form.name,
        description: this.form.description,
        author: this.form.author,
        region: this.region
      }).then(() => {
        this.$router.push('/builder');
      }).catch((e) => {
        console.log('ERROR');
        console.log(e);
      });
    }
  }
};
</script>
