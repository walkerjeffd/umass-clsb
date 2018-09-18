<template>
  <div>
    <h2>Load Project</h2>
    <p>Upload project file</p>
    <input type="file" @change="setFile">
    <button @click="loadFile">Load File</button>
    <div v-if="status === 'ready'">
      Select a project file from your computer and press Load File
    </div>
    <div v-else-if="status === 'loading'">
      Loading file, please wait...
    </div>
    <div v-else-if="status === 'loaded'">
      File has been loaded, navigating to scenario builder...
    </div>
    <div v-else-if="status === 'error'">
      Failed to load file, please try again or start a new project.
      <div v-if="error" style="color:red">{{ error.toString() }}</div>
    </div>
  </div>
</template>

<script>
import { mapActions } from 'vuex';

export default {
  name: 'project-load',
  data() {
    return {
      file: null,
      status: 'ready',
      error: null
    };
  },
  methods: {
    ...mapActions(['loadProjectFile']),
    setFile(ev) {
      const { files } = ev.target;

      if (files.length > 1) {
        alert('Only select one file');
        return null;
      }
      if (files.length === 0) {
        alert('No file selected');
        return null;
      }

      [this.file] = files;
    },
    loadFile() {
      if (!this.file) {
        alert('No file selected');
        return null;
      }

      this.status = 'loading';

      const reader = new FileReader();
      reader.onload = (e) => {
        let json;
        try {
          json = JSON.parse(e.target.result);
        } catch (err) {
          this.status = 'error';
          console.error(err);
          return null;
        }

        return this.loadProjectFile(json)
          .then(() => {
            this.status = 'loaded';
            return setTimeout(() => {
              this.$router.push('/builder');
            }, 2000);
          })
          .catch((err) => {
            this.status = 'error';
            this.error = err;
            console.error(err);
          });
      };

      return reader.readAsText(this.file);
    }
  }
};
</script>

<style>

</style>
