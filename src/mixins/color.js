import * as d3 from 'd3';

const mixin = {
  computed: {
    colorScale() {
      // translates value from [0, 1] -> color

      return d3.scaleSequential(d3.interpolateViridis);
      // return d3.scaleSequential(d3.interpolateInferno);
      // return d3.scaleSequential(d3.interpolateWarm);
      // return d3.scaleSequential(d3.interpolateCool);
    }
  }
};

export default mixin;
