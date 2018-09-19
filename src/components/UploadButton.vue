<template>
  <v-btn color="primary" class="jbtn-file"> {{ title }}<input
    type="file" v-on:change="fileSelected"></v-btn>
</template>

<script>
export default {
  name: 'upload-button',
  props: {
    selectedCallback: Function,
    title: String
  },
  methods: {
    fileSelected(e) {
      if (e.target.files.length > 0) {
        this.$emit('input', e.target.files[0]);
      }
      // if (this.selectedCallback) {
      //   if (e.target.files[0]) {
      //     this.selectedCallback(e.target.files[0]);
      //   } else {
      //     this.selectedCallback(null);
      //   }
      // }
    }
  }
};
</script>

<style scoped>
  .jbtn-file {
    cursor: pointer;
    position: relative;
    overflow: hidden;
  }

  .jbtn-file input[type=file] {
    position: absolute;
    top: 0;
    right: 0;
    min-width: 100%;
    min-height: 100%;
    text-align: right;
    filter: alpha(opacity=0);
    opacity: 0;
    outline: none;
    cursor: inherit;
    display: block;
  }
</style>
