import * as d3 from 'd3';

const mixin = {
  methods: {
    getColorScale(variable) {
      // translates value from [0, 1] -> color

      // const scale = d3.scaleSequential(d3.interpolateInferno);
      // const scale = d3.scaleSequential(d3.interpolateWarm);
      // const scale = d3.scaleSequential(d3.interpolateCool);
      const scale = d3.scaleSequential(d3.interpolateViridis);

      if (variable.scale.type === 'quantile') {
        const nQuantile = variable.scale.nQuantile;
        scale.domain([0, 1 - (1 / nQuantile)]);
      }

      if (variable.scale.reverse) {
        console.log('reverse');
        scale.domain(scale.domain().reverse());
      }

      return scale;
    }
  }
};

export default mixin;
