<template>
</template>

<script>
import MapLegend from '@/components/MapLegend.vue';

export default {
  name: 'map-card',
  props: ['variables', 'barriers', 'variable'],
  components: {
    MapLegend
  },
  data() {
    return {
      selected
    }
  }
};
</script>

<style>

</style>
