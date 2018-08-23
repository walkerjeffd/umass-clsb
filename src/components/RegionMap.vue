<template>
  <div>
    <div v-if="type === 'huc8' && huc8.selected.feature">
      Selected HUC8: {{ huc8.selected.feature.properties.name }}
      ({{ huc8.selected.feature.properties.huc8 }})
    </div>
    <div class="region-map"></div>
    <div>
      <button @click.prevent="loadRegion">Load Barriers</button>
    </div>
  </div>
</template>

<script>
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw';
import 'leaflet-draw/dist/leaflet.draw.css';
import axios from 'axios';
import geoJsonArea from '@mapbox/geojson-area';

// const geoJsonArea = require('@mapbox/geojson-area');
require('leaflet-bing-layer');

export default {
  props: ['type', 'feature'],
  data() {
    return {
      map: null,
      draw: {
        selected: {
          layer: new L.FeatureGroup(),
          feature: null
        },
        control: null
      },
      huc8: {
        features: {
          layer: L.geoJson()
            .on('click', (e) => {
              this.selectHuc8(e.layer.toGeoJSON());
            }),
          data: null,
        },
        selected: {
          layer: new L.FeatureGroup()
            .on('click', () => {
              this.huc8.selected.layer.clearLayers();
              this.huc8.selected.feature = null;
            }),
          feature: null
        }
      }
    };
  },
  computed: {
  },
  watch: {
    type() {
      this.setType(this.type);
    },
  },
  mounted() {
    this.map = L.map(this.$el.getElementsByClassName('region-map')[0], {
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

    this.draw.control = new L.Control.Draw({
      position: 'topright',
      draw: {
        circle: false,
        polygon: {
          allowIntersection: false, // Restricts shapes to simple polygons
        },
        polyline: false,
        marker: false
      },
      edit: {
        featureGroup: this.draw.selected.layer
      }
    });
    this.map.on(L.Draw.Event.CREATED, ({ layer }) => {
      const { selected } = this.draw;
      if (selected.layer.getLayers().length >= 1) {
        selected.layer.clearLayers();
        selected.feature = null;
      }
      selected.layer.addLayer(layer);

      const feature = selected.layer.toGeoJSON().features[0].geometry;
      this.draw.selected.feature = feature;

      const areaKm2 = geoJsonArea.geometry(feature) / 1e6;
      console.log('area (km2) = ', areaKm2);

      if (areaKm2 > 1000) {
        alert(`Polygon area (${areaKm2.toFixed(1)} km2) exceeds maximum (1000 km2)`);
      }
    });

    this.setType(this.type, true);
  },
  methods: {
    loadRegion() {
      let feature = null;
      let selected;

      if (this.type === 'draw') {
        selected = this.draw.selected.layer;
      } else if (this.type === 'huc8') {
        selected = this.huc8.selected.layer;
      }

      if (selected.getLayers().length === 1) {
        [feature] = selected.toGeoJSON().features;
      }
      this.$emit('loadRegion', feature);
    },
    selectHuc8(feature) {
      this.huc8.selected.feature = feature;
      this.huc8.selected.layer.clearLayers();
      const layer = L.geoJson(this.huc8.selected.feature).getLayers()[0].setStyle({ color: '#FF0000' });
      this.huc8.selected.layer.addLayer(layer);
    },
    setType(type, initial) {
      if (initial && this.feature) {
        // load initial feature
        if (this.type === 'draw') {
          this.draw.selected.feature = L.geoJson(this.feature).getLayers()[0];
          this.draw.selected.layer.addLayer(this.draw.selected.feature);
        } else if (this.type === 'huc8') {
          this.selectHuc8(this.feature);
        }
      }
      if (type === 'draw') {
        this.map.addControl(this.draw.control);
        this.map.addLayer(this.draw.selected.layer);
        this.huc8.selected.layer.clearLayers();
      } else {
        this.map.removeControl(this.draw.control);
        this.map.removeLayer(this.draw.selected.layer);
      }

      if (type === 'huc8') {
        if (!this.huc8.features.data) {
          axios.get('/static/huc8.json')
            .then((response) => {
              this.huc8.features.data = response.data.features;
              this.huc8.features.layer.addData(this.huc8.features.data);

              this.map.addLayer(this.huc8.features.layer);
              this.map.addLayer(this.huc8.selected.layer);
            });
        } else {
          this.map.addLayer(this.huc8.features.layer);
          this.map.addLayer(this.huc8.selected.layer);
        }
        this.draw.selected.layer.clearLayers();
      } else {
        this.map.removeLayer(this.huc8.features.layer);
        this.map.removeLayer(this.huc8.selected.layer);
      }

    }
  }
};
</script>

<style scoped>
.region-map {
  width: 600px;
  height: 600px;
}
</style>
