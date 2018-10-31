<template>
  <div class="legend" v-show="variable">
  </div>
</template>

<script>
import * as d3 from 'd3';

import colorMixin from '@/mixins/color';
import variableMixin from '@/mixins/variable';

export default {
  name: 'map-legend',
  mixins: [colorMixin, variableMixin],
  props: {
    id: {
      type: String,
      required: true,
    },
    height: {
      type: Number,
      default: 20,
      required: false,
    },
    maxWidth: {
      type: Number,
      required: false
    },
    margins: {
      type: Object,
      default() {
        return {
          left: 0,
          right: 0,
        };
      },
      required: false,
    },
    variable: {
      type: Object,
      required: true
    },
    data: {
      type: Array,
      required: true
    },
    show: {
      type: Boolean,
      required: true
    }
  },
  data() {
    return {
      svg: null,
      axisHeight: 30,
      width: 576
    };
  },
  computed: {
    variableScale() {
      return this.getVariableScale(this.variable, this.data);
    },
    colorScale() {
      return this.getColorScale(this.variable);
    }
  },
  mounted() {
    this.svg = d3.select(this.$el).append('svg');

    this.render();

    window.addEventListener('resize', this.render);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.render);
  },
  watch: {
    variable() {
      this.render();
    },
    data() {
      this.render();
    },
    show() {
      this.render();
    }
  },
  methods: {
    render() {
      this.resize();
      this.clear();

      switch (this.variable.scale.type) {
        case 'continuous':
          this.renderContinuous();
          break;
        case 'quantile':
          this.renderQuantile();
          break;
        default:
          console.log('ERROR: invalid variable scale type');
      }
    },
    resize() {
      let width = this.$el.offsetWidth - this.margins.left - this.margins.right;

      if (this.$el.offsetWidth <= 0) {
        width = 576;
      }

      if (this.maxWidth && width > this.maxWidth) {
        width = this.maxWidth;
      }

      this.width = width;

      const fullWidth = this.width + this.margins.left + this.margins.right;
      const fullHeight = this.height + this.axisHeight;

      this.svg.attr('width', fullWidth)
        .attr('height', fullHeight);
    },
    clear() {
      this.svg.select('g.legend-axis').remove();
      this.svg.select('defs').remove();
      this.svg.selectAll('rect').remove();
    },
    renderContinuous() {
      const defs = this.svg.append('defs');

      const linearGradient = defs.append('linearGradient')
        .attr('id', `linear-gradient-${this.id}`);

      linearGradient
        .attr('x1', '0%')
        .attr('y1', '0%')
        .attr('x2', '100%')
        .attr('y2', '0%');

      this.svg.append('rect')
        .attr('width', this.width)
        .attr('height', this.height)
        .attr('x', this.margins.left)
        .style('fill', `url(#linear-gradient-${this.id}`);

      const delta = 0.2;
      const offsets = d3.range(0, 1, delta);
      offsets.push(1);

      linearGradient.selectAll('stop')
        .data(offsets)
        .enter()
        .append('stop')
        .attr('offset', d => d)
        .attr('stop-color', d => this.colorScale(d));

      this.svg.append('g')
        .attr('class', 'legend-axis')
        .attr('transform', `translate(${this.margins.left}, ${this.height})`);

      this.renderAxisContinuous();
    },
    renderAxisContinuous() {
      const axisScale = this.variableScale
        .copy()
        .rangeRound([0, +this.width]);
      const axisFormatter = d3.format(this.variable ? this.variable.formats.axis : ',.1f');
      const axis = d3.axisBottom(axisScale);

      axis.ticks(8, axisFormatter);
      this.svg.select('g.legend-axis')
        .call(axis);

      if (this.variableScale.clamp() && this.variable.scale.transform) {
        if (this.variable.scale.transform.min) {
          const tick = this.svg.select('g.tick text');
          if (tick.datum() === this.variable.scale.transform.min) {
            tick.text(`< ${tick.text()}`);
          }
        }
        if (this.variable.scale.transform.max) {
          const ticks = this.svg.selectAll('g.tick text')
            .filter(function () { // eslint-disable-line func-names
              return d3.select(this).text() !== '';
            });
          const tick = d3.select(ticks.nodes()[ticks.size() - 1]);
          if (tick.datum() === this.variable.scale.transform.max) {
            tick.text(`> ${tick.text()}`);
          }
        }
      }
    },
    renderQuantile() {
      const quantileDomain = this.variableScale.range();

      const nColors = quantileDomain.length;

      const rectWidth = this.width / nColors;
      const rect = this.svg.selectAll('rect')
        .data(quantileDomain);

      rect.enter()
        .append('rect')
        .attr('width', rectWidth + 1)
        .attr('height', this.height)
        .attr('x', d => this.margins.left + (d * this.width))
        .style('fill', this.colorScale);

      this.svg.append('g')
        .attr('class', 'legend-axis quantile')
        .attr('transform', `translate(${this.margins.left}, ${this.height})`);

      this.renderAxisQuantile();
    },
    renderAxisQuantile() {
      const axisFormatter = d3.format(this.variable ? this.variable.formats.text : ',.1f');

      const extent = d3.extent(this.data, d => d[this.variable.id]);

      const quantiles = this.variableScale.quantiles();

      quantiles.unshift(extent[0]);
      quantiles.push(extent[1]);

      const quantilesFormatted = quantiles.map(axisFormatter);

      const tickLabels = [];
      for (let i = 0; i < quantilesFormatted.length - 1; i++) {
        tickLabels.push(`${quantilesFormatted[i]} - ${quantilesFormatted[i + 1]}`);
      }

      const labelWidth = this.width / tickLabels.length;

      const axisScale = d3.scalePoint()
        .domain(tickLabels)
        .range([labelWidth / 2, +this.width - (labelWidth / 2)]);

      const axis = d3.axisBottom(axisScale);

      this.svg.select('g.legend-axis')
        .call(axis);
    }
  },
};
</script>

<style>
g.legend-axis.quantile path {
  display: none;
}
</style>
