<template>
  <div class="barriers-map">
    <v-snackbar
      top
      v-model="showZoomWarning">
      Warning! Satellite and street map basemaps are not available at this zoom level.
      <v-btn flat color="primary" @click.native="showZoomWarning = false">Close</v-btn>
    </v-snackbar>
  </div>
</template>

<script>
import * as d3 from 'd3';
import d3Tip from 'd3-tip';
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw';
import 'leaflet-draw/dist/leaflet.draw.css';
import * as turf from '@turf/turf';

require('leaflet-bing-layer');

// customize draw toolbar buttons
L.drawLocal.draw.toolbar.buttons.polygon = 'Draw polygon to select multiple barriers';
L.drawLocal.draw.toolbar.buttons.rectangle = 'Draw rectangle to select multiple barriers';

L.Control.Legend = L.Control.extend({
  onAdd: () => {
    const div = L.DomUtil.create('div', 'legend-control');

    const types = [
      {
        type: 'dam',
        label: 'Dam',
        symbol: d3.symbol().type(d3.symbolSquare).size(100)
      },
      {
        type: 'crossing',
        label: 'Crossing',
        symbol: d3.symbol().type(d3.symbolCircle).size(100)
      }
    ];

    const size = 16;

    d3.select(div)
      .selectAll('svg')
      .data(types)
      .enter()
      .append('div')
      .style('height', `${size}px`)
      .style('margin', '2px')
      .each(function appendSvg(d) {
        const svg = d3.select(this)
          .append('svg')
          .attr('width', size)
          .attr('height', size);

        svg.append('path')
          .attr('d', p => p.symbol())
          .attr('fill', '#666666')
          .attr('transform', `translate(${size / 2},${size / 2})`);

        d3.select(this)
          .append('span')
          .text(d.label)
          .style('vertical-align', 'top')
          .style('padding-left', '5px')
          .style('color', 'rgba(0,0,0,0.87)');
      });

    return div;
  },
  onRemove: () => null
});
L.control.legend = opts => new L.Control.Legend(opts);

export default {
  props: ['selected', 'barriers', 'region', 'variable', 'colorScale', 'variableScale', 'highlight'],
  data() {
    return {
      showZoomWarning: false,
      map: null,
      svg: null,
      disableClick: false,
      zoomLevel: 0,
      tip: d3Tip()
        .attr('class', 'd3-tip'),
      layers: {
        barriers: null,
        selected: null,
        highlight: null,
        region: null
      },
      draw: {
        selected: {
          layer: new L.FeatureGroup(),
          feature: null
        },
        control: null
      },
    };
  },
  computed: {
    path() {
      const vm = this;
      function projectPoint(x, y) {
        const point = vm.map.latLngToLayerPoint(new L.LatLng(y, x));
        this.stream.point(point.x, point.y);
      }
      const geoTransform = d3.geoTransform({ point: projectPoint });
      const path = d3.geoPath().projection(geoTransform);
      return path;
    },
    pointRadius() {
      return this.zoomLevel - 6;
    }
  },
  mounted() {
    this.map = L.map(this.$el, {
      center: [42, -72],
      zoom: 7,
      zoomControl: false
    });
    this.zoomLevel = this.map.getZoom();

    L.control.zoom({
      maxZoom: 18,
      minZoom: 5,
      position: 'topright'
    }).addTo(this.map);

    setTimeout(() => {
      this.map.invalidateSize();
    }, 400);

    L.control.scale({ position: 'bottomright' }).addTo(this.map);

    const basemaps = {
      'Open Street Map': L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors',
      }),
      'Bing Satellite': L.tileLayer.bing('AvSDmEuhbTKvL0ui4AlHwQNBVuDI2QBBoeODy1vwOz5sW_kDnBx3UMtUxbjsZ3bN'),
      'No Basemap': L.tileLayer('').addTo(this.map)
    };

    const overlays = [
      {
        layer: 'sheds:detailed_flowlines',
        label: 'Flowlines',
        opacity: 0.5,
        visible: true,
      },
      {
        layer: 'sheds:waterbodies',
        label: 'Waterbodies',
        opacity: 0.5,
        visible: true,
      },
      {
        layer: 'sheds:wbdhu12',
        label: 'HUC12 Basins',
        opacity: 0.5,
        visible: true,
      }
    ];
    const overlayLayers = {};
    overlays.forEach((d) => {
      const key = '<img src="http://ecosheds.org:8080/geoserver/wms?' +
        'REQUEST=GetLegendGraphic&VERSION=1.0.0&FORMAT=image/png' +
        `&WIDTH=20&HEIGHT=20&LAYER=${d.layer}` +
        `&LEGEND_OPTIONS=fontAntiAliasing:true;forceLabels:off"> ${d.label}`;
      overlayLayers[key] = L.tileLayer.wms('http://ecosheds.org:8080/geoserver/wms', {
        layers: d.layer,
        format: 'image/png',
        transparent: true,
        opacity: d.opacity || 0.5,
        minZoom: d.minZoom || -Infinity,
        maxZoom: d.maxZoom || Infinity,
      });
      if (d.visible) overlayLayers[key].addTo(this.map);
    });

    L.control.layers(basemaps, overlayLayers, {
      position: 'topright',
      collapsed: true,
    }).addTo(this.map);

    L.control.legend({ position: 'topright' }).addTo(this.map);

    this.draw.control = new L.Control.Draw({
      position: 'topright',
      draw: {
        rectangle: {
        },
        circle: false,
        circlemarker: false,
        polygon: {
          allowIntersection: false, // Restricts shapes to simple polygons
        },
        polyline: false,
        marker: false
      },
      edit: {
        featureGroup: this.draw.selected.layer,
        edit: false,
        remove: false
      }
    }).addTo(this.map);
    // this.map.addLayer(this.draw.selected.layer);

    this.map.getPane('mapPane').style.zIndex = 0;
    this.map.getPane('tilePane').style.zIndex = 0;
    this.map.getPane('overlayPane').style.zIndex = 1;
    this.map.getPane('popupPane').style.zIndex = 1;
    this.map.getPane('tooltipPane').style.zIndex = 1;

    const controlElements = this.$el.getElementsByClassName('leaflet-control-container')[0].children;

    for (let i = 0; i < controlElements.length; i++) {
      controlElements[i].style.zIndex = 1;
    }

    // set up svg
    this.svg = d3.select(this.map.getPanes().overlayPane).append('svg');
    const g = this.svg.append('g').attr('class', 'leaflet-zoom-hide');
    this.layers.region = g.append('g').attr('class', 'region');
    this.layers.barriers = g.append('g').attr('class', 'barriers');
    this.layers.highlight = g.append('g').attr('class', 'highlight');
    this.layers.selected = g.append('g').attr('class', 'selected');

    this.svg.call(this.tip.html(d => `
      <strong>Barrier ID:</strong> ${d.id}<br>
      <strong>Type:</strong> ${d.type}<br>
      <strong>Surveyed:</strong> ${d.surveyed}<br>
      <strong>Restoration Potential:</strong> ${d.effect.toFixed(1)}<br>
      <strong>Connectivity Gain:</strong> ${d.delta.toFixed(1)}<br>
      <strong>Aquatic Passability:</strong> ${d.aquatic.toFixed(2)}<br>
    `));

    let moveTimeout;
    this.map.on('movestart', () => {
      window.clearTimeout(moveTimeout);
      this.disableClick = true;
    });
    this.map.on('moveend', () => {
      moveTimeout = setTimeout(() => {
        this.disableClick = false;
      }, 100);
    });
    this.map.on('zoomend', () => {
      this.zoomLevel = this.map.getZoom();
      if (this.zoomLevel > 18) {
        this.showZoomWarning = true;
      } else {
        this.showZoomWarning = false;
      }
      this.render();
    });
    this.map.on('draw:created', ({ layer }) => {
      const points = {
        type: 'FeatureCollection',
        features: this.barriers.map(b => ({
          type: 'Feature',
          properties: {
            id: b.id
          },
          geometry: {
            type: 'Point',
            coordinates: [b.lon, b.lat]
          }
        }))
      };
      const polygon = layer.toGeoJSON();

      const selected = turf.pointsWithinPolygon(points, polygon);
      const selectedIds = selected.features.map(d => d.properties.id);

      selectedIds.forEach((id) => {
        const barrier = this.barriers.find(d => d.id === id);
        this.$emit('add-barrier', barrier);
      });
    });


    this.fitToRegion();
    this.render();
  },
  watch: {
    selected() {
      this.drawSelected();
    },
    variable() {
      this.render();
    },
    barriers() {
      this.render();
    },
    highlight: {
      handler() {
        this.drawHighlight();
      },
      deep: true
    },
    region() {
      this.fitToRegion();
    }
  },
  methods: {
    render() {
      this.resizeSvg();
      this.drawRegion();
      this.drawBarriers();
      this.drawHighlight();
      this.drawSelected();
    },
    drawRegion() {
      this.layers.region.selectAll('path').remove();

      if (!this.region) return;

      this.layers.region
        .append('path')
        .datum(this.region.feature)
        .attr('class', 'region')
        .attr('d', this.path);
    },
    resizeSvg() {
      if (!this.region) return;

      const bounds = this.path.bounds(this.region.feature);
      const topLeft = bounds[0];
      const bottomRight = bounds[1];
      const padding = 10; // padding on each side

      this.svg.attr('width', (bottomRight[0] - topLeft[0]) + padding)
        .attr('height', ((bottomRight[1] - topLeft[1]) + padding))
        .style('left', `${topLeft[0] - (padding / 2)}px`)
        .style('top', `${topLeft[1] - (padding / 2)}px`);

      this.svg.select('g')
        .attr('transform', `translate(${-(topLeft[0] - (padding / 2))},${-(topLeft[1] - (padding / 2))})`);
    },
    fitToRegion() {
      if (!this.region) return;
      const bounds = d3.geoBounds(this.region.feature);
      const topLeft = bounds[0];
      const bottomRight = bounds[1];
      this.map.fitBounds([
        [topLeft[1], topLeft[0]],
        [bottomRight[1], bottomRight[0]]
      ]);
    },
    drawBarriers() {
      const r = this.pointRadius;
      const tip = this.tip;

      this.layers.barriers.selectAll('path.barrier').remove();

      if (!this.barriers || !this.variableScale || !this.colorScale) return;

      const typePaths = {
        dam: d3.symbol().type(d3.symbolSquare).size(r * 20),
        crossing: d3.symbol().type(d3.symbolCircle).size(r * 10),
      };
      const highlightTypePaths = {
        dam: d3.symbol().type(d3.symbolSquare).size(r * 20 * 3),
        crossing: d3.symbol().type(d3.symbolCircle).size(r * 10 * 3),
      };

      const barriers = this.layers.barriers
        .selectAll('path.barrier')
        .data(this.barriers, d => d.id);

      barriers.enter()
        .append('path')
        .attr('class', 'barrier')
        .merge(barriers)
        .attr('transform', (d) => {
          const point = this.map.latLngToLayerPoint(new L.LatLng(d.lat, d.lon));
          return `translate(${point.x},${point.y})`;
        })
        .attr('d', d => typePaths[d.type](d))
        .attr('fill', (d) => {
          const value = d[this.variable.id];
          const colorValue = this.variableScale(value);
          const color = this.colorScale(colorValue);

          return color;
        })
        .on('mouseenter', function (d) { // eslint-disable-line func-names
          d3.select(this).attr('d', b => highlightTypePaths[b.type](b));
          tip.show(d, this);
        })
        .on('mouseout', function (d) { // eslint-disable-line func-names
          d3.select(this).attr('d', b => typePaths[b.type](b));
          tip.hide(d, this);
        })
        .on('click', (d) => {
          if (this.selected.map(b => b.id).includes(d.id)) {
            this.$emit('remove-barrier', d);
          } else {
            this.$emit('add-barrier', d);
          }
        });

      barriers.exit().remove();
    },
    drawHighlight() {
      const r = this.pointRadius;

      const typePaths = {
        dam: d3.symbol().type(d3.symbolSquare).size(r * 20 * 3),
        crossing: d3.symbol().type(d3.symbolCircle).size(r * 10 * 3),
      };

      let barriers = [];
      if (this.highlight.surveyed) {
        barriers = [
          ...barriers,
          ...this.barriers.filter(d => (d.type === 'crossing' && d.surveyed))
        ];
      }
      if (this.highlight.dams) {
        barriers = [
          ...barriers,
          ...this.barriers.filter(d => d.type === 'dam')
        ];
      }

      const highlights = this.layers.highlight
        .selectAll('path.highlight')
        .data(barriers, d => d.id);

      highlights.enter()
        .append('path')
        .attr('class', 'highlight')
        .attr('fill', 'none')
        .attr('stroke', (d) => {
          if (d.type === 'crossing' && d.surveyed) {
            return '#FF8F00';
          }
          if (d.type === 'dam') {
            return '#D500FF';
          }
        })
        .attr('stroke-width', '1.5px')
        .merge(highlights)
        .attr('transform', (d) => {
          const point = this.map.latLngToLayerPoint(new L.LatLng(d.lat, d.lon));
          return `translate(${point.x},${point.y})`;
        })
        .attr('d', d => typePaths[d.type](d));

      highlights.exit().remove();
    },
    drawSelected() {
      const r = this.pointRadius;

      const typePaths = {
        dam: d3.symbol().type(d3.symbolSquare).size(r * 20 * 3),
        crossing: d3.symbol().type(d3.symbolCircle).size(r * 10 * 3),
      };


      if (this.selected) {
        const selected = this.layers.selected
          .selectAll('path.selected')
          .data(this.selected, d => d.id);

        selected.enter()
          .append('path')
          .attr('class', 'selected')
          .attr('fill', 'none')
          .attr('stroke', 'red')
          .attr('stroke-width', '2px')
          .merge(selected)
          .attr('transform', (d) => {
            const point = this.map.latLngToLayerPoint(new L.LatLng(d.lat, d.lon));
            return `translate(${point.x},${point.y})`;
          })
          .attr('d', d => typePaths[d.type](d));

        selected.exit().remove();
      }
    }
  }
};
</script>

<style>
.barriers-map {
  width: 100%;
  height: 100%;
}

path.region {
  fill: none;
  stroke: #444444;
  stroke-width: 2px;
}

path.barrier {
  cursor: pointer;
  pointer-events: visible !important;
}

path.selected {
  cursor: pointer;
  pointer-events: none;
}

.legend-control {
  color: #555;
  background: white;
  padding: 5px;
  border-radius: 5px;
  border: 2px solid rgb(0,0,0,0.2);
}

/*
  d3-tip -----------------------------------------------------------
  https://rawgit.com/Caged/d3-tip/master/examples/example-styles.css
*/
.d3-tip {
  line-height: 1;
  padding: 12px;
  background: rgba(255, 255, 255, 0.8);
  color: #000;
  border-radius: 2px;
  pointer-events: none;
  font-family: sans-serif;
}
</style>
