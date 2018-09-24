import * as d3 from 'd3';

const mixin = {
  computed: {
    variableDomain() {
      // compute value domain from dataset
      if (!this.variable || !this.barriers) return [0, 1];

      return d3.extent(this.barriers, d => d[this.variable.id]);
    },
    variableScale() {
      // transform value -> [0, 1]
      if (!this.variable) return d3.scaleIdentity();

      const transform = this.variable.transform;

      switch (transform.type) {
        case 'log':
          return d3.scaleLog()
            .domain(this.variableDomain)
            .range([0, 1]);
        case 'pow':
          return d3.scalePow()
            .exponent(transform.exponent)
            .domain(this.variableDomain)
            .range([0, 1]);
        default:
          return d3.scaleLinear()
            .domain(this.variableDomain)
            .range([0, 1]);
      }
    }
  }
};

export default mixin;
