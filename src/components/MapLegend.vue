<template>
  <div class="legend" v-show="variable">
  </div>
</template>

<script>
import * as d3 from 'd3';

import colorMixin from '@/mixins/color';
// import variableMixin from '@/mixins/variable';

export default {
  mixins: [colorMixin],
  props: {
    id: {
      type: String,
      required: true,
    },
    width: {
      type: Number,
      default: 400,
      required: true,
    },
    height: {
      type: Number,
      default: 20,
      required: false,
    },
    margins: {
      type: Object,
      default() {
        return {
          left: 20,
          right: 20,
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
    }
  },
  data() {
    return {
      svg: null,
      axisHeight: 30
    };
  },
  computed: {
    variableDomain() {
      // compute value domain from dataset
      if (!this.variable || !this.data) return [0, 1];

      return d3.extent(this.data, d => d[this.variable.id]);
    },
    variableScale() {
      // transform value -> [0, 1]
      if (!this.variable) return d3.scaleIdentity();

      const transform = this.variable.transform;

      let scale;
      switch (transform.type) {
        case 'log':
          scale = d3.scaleLog();
          break;
        case 'pow':
          scale = d3.scalePow()
            .exponent(transform.exponent);
          break;
        default:
          scale = d3.scaleLinear();
          break;
      }
      return scale
        .domain(this.variableDomain)
        .range([0, 1]);
    },
    axisScale() {
      const scale = this.variableScale.copy();
      return scale
        .domain(this.variableDomain)
        .rangeRound([0, +this.width]);
    },
    axisFormatter() {
      return d3.format(this.variable ? this.variable.formats.axis : ',.1f');
    },
    axis() {
      return d3.axisBottom(this.axisScale);
    }
  },
  mounted() {
    this.svg = d3.select(this.$el).append('svg')
      .attr('width', this.width + this.margins.left + this.margins.right)
      .attr('height', this.height + this.axisHeight);

    this.render();
  },
  watch: {
    variable() {
      this.render();
    }
  },
  methods: {
    render() {
      this.clear();
      this.renderGradient();
    },
    clear() {
      this.svg.select('g.legend-axis').remove();

      this.svg.select('defs').remove();

      this.svg.selectAll('rect').remove();
    },
    renderGradient() {
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

      this.renderAxisTicks();
    },
    renderAxisTicks() {
      this.axis
        .ticks(8, this.axisFormatter);
      this.svg.select('g.legend-axis')
        .call(this.axis);
    },
  },
};
</script>

<style>
</style>
