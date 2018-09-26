<template>
  <div>
    <div class="barriers-map"></div>
  </div>
</template>

<script>
import * as d3 from 'd3';
import d3Tip from 'd3-tip';
import 'leaflet/dist/leaflet.css';

import colorMixin from '@/mixins/color';
import variableMixin from '@/mixins/variable';

d3.tip = d3Tip;

require('leaflet-bing-layer');

export default {
  props: ['selected', 'barriers', 'region', 'variable', 'colors'],
  mixins: [variableMixin, colorMixin],
  data() {
    return {
      map: null,
      svg: null,
      disableClick: false,
      zoomLevel: 0,
      tip: d3.tip()
        .attr('class', 'd3-tip'),
      layers: {
        barriers: null,
        selected: null,
        region: null
      }
    };
  },
  computed: {
    variableScale() {
      return this.getVariableScale(this.variable, this.barriers);
    },
    colorScale() {
      return this.getColorScale(this.variable);
    },
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
    this.map = L.map(this.$el.getElementsByClassName('barriers-map')[0], {
      center: [42, -72],
      zoom: 7,
      maxZoom: 18,
      minZoom: 5,
    });
    this.zoomLevel = this.map.getZoom();

    setTimeout(() => {
      this.map.invalidateSize();
    }, 400);

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
    this.layers.selected = g.append('g').attr('class', 'selected');

    this.svg.call(this.tip.html(d => `
      <strong>Barrier ID:</strong> ${d.id}<br>
      <strong>Type:</strong> ${d.type}<br>
      <strong>Effect:</strong> ${d.effect.toFixed(1)}
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
      this.render();
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
    }
  },
  methods: {
    render() {
      this.resizeSvg();
      this.drawRegion();
      this.drawBarriers();
      this.drawSelected();
    },
    drawRegion() {
      this.layers.region.selectAll('path').remove();

      if (this.region) {
        this.layers.region
          .append('path')
          .datum(this.region.feature)
          .attr('class', 'region')
          .attr('d', this.path);
      }
    },
    resizeSvg() {
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
      this.layers.barriers.selectAll('circle').remove();

      if (this.barriers) {
        const circles = this.layers.barriers
          .selectAll('circle')
          .data(this.barriers, d => d.id);

        circles.enter()
          .append('circle')
          .attr('class', 'barrier')
          .attr('r', r)
          .attr('cx', d => this.map.latLngToLayerPoint(new L.LatLng(d.lat, d.lon)).x)
          .attr('cy', d => this.map.latLngToLayerPoint(new L.LatLng(d.lat, d.lon)).y)
          .attr('fill', (d) => {
            const value = d[this.variable.id];
            const colorValue = this.variableScale(value);
            const color = this.colorScale(colorValue);

            return color;
          })
          .on('mouseenter', function (d) { // eslint-disable-line func-names
            d3.select(this).attr('r', r * 2);
            tip.show(d, this);
          })
          .on('mouseout', function (d) { // eslint-disable-line func-names
            d3.select(this).attr('r', r);
            tip.hide(d, this);
          })
          .on('click', (d) => {
            this.$emit('add-barrier', d);
          });
      }
    },
    drawSelected() {
      const r = this.pointRadius;
      const tip = this.tip;

      if (this.selected) {
        const circles = this.layers.selected
          .selectAll('circle')
          .data(this.selected, d => d.id);

        circles.enter()
          .append('circle')
          .attr('class', 'selected')
          .attr('fill', 'none')
          .attr('stroke', 'red')
          .merge(circles)
          .attr('r', r + 2)
          .attr('cx', d => this.map.latLngToLayerPoint(new L.LatLng(d.lat, d.lon)).x)
          .attr('cy', d => this.map.latLngToLayerPoint(new L.LatLng(d.lat, d.lon)).y)
          .on('mouseenter', function (d) { // eslint-disable-line func-names
            d3.select(this).attr('r', r * 2);
            tip.show(d, this);
          })
          .on('mouseout', function (d) { // eslint-disable-line func-names
            d3.select(this).attr('r', r * 1.3);
            tip.hide(d, this);
          })
          .on('click', (d) => {
            this.$emit('remove-barrier', d);
          });

        circles.exit().remove();
      }
    }
  }
};
</script>

<style>
.barriers-map {
  width: 100%;
  height: 600px;
}

path.region {
  fill: none;
  stroke: #444444;
  stroke-width: 2px;
}

circle.barrier {
  cursor: pointer;
  pointer-events: visible;
}

circle.selected {
  cursor: pointer;
  pointer-events: visible;
  stroke-width: 2px;
}

/*
  d3-tip -----------------------------------------------------------
  https://rawgit.com/Caged/d3-tip/master/examples/example-styles.css
*/
/*.d3-tip {
  line-height: 1;
  font-weight: bold;
  padding: 12px;
  background: rgba(0, 0, 0, 0.8);
  color: #fff;
  border-radius: 2px;
  pointer-events: none;
  font-family: sans-serif;
}
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

/* Creates a small triangle extender for the tooltip */
/*.d3-tip:after {
  box-sizing: border-box;
  display: inline;
  font-size: 10px;
  width: 100%;
  line-height: 1;
  color: rgba(0, 0, 0, 0.8);
  position: absolute;
  pointer-events: none;
}
*/
/* Northward tooltips */
/*.d3-tip.n:after {
  content: "\25BC";
  margin: -1px 0 0 0;
  top: 100%;
  left: 0;
  text-align: center;
}
*/
/* Eastward tooltips */
/*.d3-tip.e:after {
  content: "\25C0";
  margin: -4px 0 0 0;
  top: 50%;
  left: -8px;
}
*/
/* Southward tooltips */
/*.d3-tip.s:after {
  content: "\25B2";
  margin: 0 0 1px 0;
  top: -8px;
  left: 0;
  text-align: center;
}
*/
/* Westward tooltips */
/*.d3-tip.w:after {
  content: "\25B6";
  margin: -4px 0 0 -1px;
  top: 50%;
  left: 100%;
}*/
</style>
