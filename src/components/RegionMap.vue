<template>
  <div>
    <div class="body-2">
      <div v-if="type === 'huc8'">
        <p v-if="huc8.selected.feature">
          Selected HUC8: {{ huc8.selected.feature.properties.name }}
          ({{ huc8.selected.feature.properties.huc8 }})
        </p>
        <p v-else>
          Click on a watershed (HUC8) to select it, then click Next.
        </p>
      </div>
      <div v-else-if="type === 'draw'">
        <p v-if="draw.selected.feature">
          The drawn region has an area of {{ draw.selected.feature.properties.areaKm2 | number }} sq. km.
        </p>
        <p v-else>
          Use the drawing tools (upper right corner of map) to define your region, then click Next. The custom region must be within the 13 states shown in gray and cannot be larger than {{ draw.maxArea | number }} sq. km.
        </p>
      </div>
    </div>
    <div class="region-map"></div>
  </div>
</template>

<script>
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw';
import 'leaflet-draw/dist/leaflet.draw.css';
import axios from 'axios';
import geoJsonArea from '@mapbox/geojson-area';
import * as d3 from 'd3';

import { DRAW_MAX_AREA_KM2 } from '@/constants';
import { number } from '@/filters';

export default {
  props: ['type', 'feature'],
  filters: {
    number
  },
  data() {
    return {
      map: null,
      draw: {
        selected: {
          layer: new L.FeatureGroup(),
          feature: null
        },
        control: null,
        states: {
          layer: L.geoJson([], {
            style: () => ({
              color: '#888888',
              fill: null
            })
          })
        },
        maxArea: DRAW_MAX_AREA_KM2
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
              this.clear();
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
    const el = this.$el.getElementsByClassName('region-map')[0];

    this.map = L.map(el, {
      center: [42, -72.5],
      zoom: 5,
      maxZoom: 18,
      minZoom: 5,
    });

    setTimeout(() => {
      this.map.invalidateSize();
    }, 400);

    L.control.scale({ position: 'bottomleft' }).addTo(this.map);
    const basemaps = {
      'Open Street Map': L.tileLayer('https://{s}.tile.osm.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://osm.org/copyright">OpenStreetMap</a> contributors',
      }).addTo(this.map),
      'ESRI World Imagery': L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
        attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'
      })
    };

    L.control.layers(basemaps, [], {
      position: 'topleft',
      collapsed: true,
    }).addTo(this.map);

    this.draw.control = new L.Control.Draw({
      position: 'topright',
      draw: {
        circle: false,
        circlemarker: false,
        polygon: {
          allowIntersection: false,
        },
        polyline: false,
        marker: false
      },
      edit: {
        featureGroup: this.draw.selected.layer
      }
    });
    this.map.on('draw:created', ({ layer }) => {
      this.selectDraw(layer.toGeoJSON());
    });
    this.map.on('draw:edited', ({ layers }) => {
      this.selectDraw(layers.getLayers()[0].toGeoJSON());
    });
    this.map.on('draw:deleted', () => {
      this.clear();
    });

    this.setType(this.type);

    if (this.feature) {
      if (this.type === 'draw') {
        this.selectDraw(this.feature);
      } else if (this.type === 'huc8') {
        this.selectHuc8(this.feature);
      }
      setTimeout(() => this.fitToFeature(this.feature), 1000);
    }
  },
  methods: {
    fitToFeature(feature) {
      if (!feature) return;
      const bounds = d3.geoBounds(feature);
      const topLeft = bounds[0];
      const bottomRight = bounds[1];
      this.map.fitBounds([
        [topLeft[1], topLeft[0]],
        [bottomRight[1], bottomRight[0]]
      ]);
    },
    loadRegion(feature) {
      if (feature) {
        this[this.type].selected.feature = feature;
        this.$emit('loadRegion', feature);
      } else {
        this.clear();
      }
    },
    clear() {
      this.huc8.selected.layer.clearLayers();
      this.draw.selected.layer.clearLayers();

      this.huc8.selected.feature = null;
      this.draw.selected.feature = null;

      this.$emit('loadRegion', null);
    },
    selectDraw(feature) {
      this.draw.selected.layer.clearLayers();

      if (feature) {
        feature.properties.areaKm2 = geoJsonArea.geometry(feature.geometry) / 1e6;
        const layer = L.geoJson(feature).getLayers()[0];
        this.draw.selected.layer.addLayer(layer);
      }

      this.loadRegion(feature);
    },
    selectHuc8(feature) {
      this.huc8.selected.layer.clearLayers();

      if (feature) {
        const layer = L.geoJson(feature).getLayers()[0]
          .setStyle({ color: '#FF0000' });
        this.huc8.selected.layer.addLayer(layer);
      }

      this.loadRegion(feature);
    },
    setType(type) {
      this.clear();
      let promise;

      if (type === 'draw') {
        if (this.draw.states.layer.getLayers().length === 0) {
          promise = axios.get('/static/states.json')
            .then((response) => {
              this.draw.states.layer.addData(response.data.features);
            });
        } else {
          promise = Promise.resolve();
        }
        promise.then(() => {
          this.map.addControl(this.draw.control);
          this.map.addLayer(this.draw.states.layer);
          this.map.addLayer(this.draw.selected.layer);
        });
      } else {
        this.map.removeControl(this.draw.control);
        this.map.removeLayer(this.draw.states.layer);
        this.map.removeLayer(this.draw.selected.layer);
      }

      if (type === 'huc8') {
        if (this.huc8.features.layer.getLayers().length === 0) {
          promise = axios.get('/static/huc8.json')
            .then((response) => {
              // this.huc8.features.data = response.data.features;
              this.huc8.features.layer.addData(response.data.features);
            });
        } else {
          promise = Promise.resolve();
        }
        promise.then(() => {
          this.map.addLayer(this.huc8.features.layer);
          this.map.addLayer(this.huc8.selected.layer);
        });
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
  width: 100%;
  height: 400px;
  z-index: 0;
}
</style>
