<template>
  <div>
    <div class="barriers-map"></div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import 'leaflet/dist/leaflet.css';

require('leaflet-bing-layer');

export default {
  props: ['selected'],
  data() {
    return {
      map: null,
      layers: {
        barriers: new L.LayerGroup(),
        selected: new L.LayerGroup(),
        region: new L.geoJson() // eslint-disable-line
      }
    };
  },
  computed: {
    ...mapGetters(['barriers', 'project'])
  },
  mounted() {
    this.map = L.map(this.$el.getElementsByClassName('barriers-map')[0], {
      center: [42, -72],
      zoom: 7,
      maxZoom: 18,
      minZoom: 5,
    });

    L.control.scale({ position: 'bottomleft' }).addTo(this.map);
    const basemaps = {
      'Open Street Map': L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors',
      }).addTo(this.map),
      'Bing Satellite': L.tileLayer.bing('AvSDmEuhbTKvL0ui4AlHwQNBVuDI2QBBoeODy1vwOz5sW_kDnBx3UMtUxbjsZ3bN')
    };

    L.control.layers(basemaps, [], {
      position: 'topleft',
      collapsed: true,
    }).addTo(this.map);

    this.layers.region.addTo(this.map);
    this.layers.barriers.addTo(this.map);
    this.layers.selected.addTo(this.map);

    if (this.project && this.project.region) {
      const layer = L.geoJson(this.project.region.feature, {
        interactive: false,
        style: {
          color: 'red',
          fill: false
        }
      });
      this.layers.region.addLayer(layer);
      this.map.fitBounds(layer.getBounds());
    }

    this.drawBarriers();
  },
  watch: {
    selected() {
      this.drawSelected();
    }
  },
  methods: {
    drawBarriers() {
      const layers = this.barriers.map(b => L.circleMarker([b.lat, b.lon], {
        radius: 5,
        ...this.styleBarrier(b, false)
      }).bindTooltip(`
          <div>
            barrier id: ${b.id}<br>
            barrier type: ${b.type}<br>
            delta: ${b.delta}<br>
            effect: ${b.effect}
          </div>
        `)
        .on('click', () => {
          this.$emit('add-barrier', b);
        }));

      this.layers.barriers.clearLayers();
      this.layers.barriers.addLayer(new L.LayerGroup(layers));
    },
    styleBarrier(barrier, highlight) {
      return {
        color: highlight ? 'red' : 'blue',
        fill: true
      };
    },
    drawSelected() {
      const layers = this.selected.map(b => L.circleMarker([b.lat, b.lon], {
        radius: 5,
        ...this.styleBarrier(b, true)
      }).bindTooltip(`
          <div>
            barrier id: ${b.id}<br>
            barrier type: ${b.type}<br>
            delta: ${b.delta}<br>
            effect: ${b.effect}
          </div>
        `)
        .on('click', () => {
          this.$emit('remove-barrier', b);
        }));

      this.layers.selected.clearLayers();
      this.layers.selected.addLayer(new L.LayerGroup(layers));
    }
  }
};
</script>

<style scoped>
.barriers-map {
  width: 600px;
  height: 600px;
}
</style>