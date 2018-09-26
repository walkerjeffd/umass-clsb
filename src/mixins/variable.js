import * as d3 from 'd3';

function continuousScale(variable, data) {
  const transform = variable.scale.transform;
  let domain = [0, 1];
  if (data.length >= 2) {
    domain = d3.extent(data, d => d[variable.id]);
  }

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

  if (transform.min && domain[0] < transform.min) {
    domain[0] = transform.min;
    scale = scale.clamp(true);
  }
  if (transform.max && domain[1] > transform.max) {
    domain[1] = transform.max;
    scale = scale.clamp(true);
  }

  return scale
    .domain(domain)
    .range([0, 1]);
}

function quantileScale(variable, data) {
  if (data.length < 2) return d3.scaleIdentity();

  const nQuantile = variable.scale.nQuantile || 4;
  const probs = d3.range(0, 1, 1 / nQuantile);

  const scale = d3.scaleQuantile()
    .domain(data.map(d => d[variable.id]))
    .range(probs);

  return scale;
}

function categoricalScale() {
  return d3.scaleIdentity();
}

const mixin = {
  methods: {
    getVariableScale(variable, data) {
      if (!variable || !data) {
        return d3.scaleIdentity();
      }

      let scale;
      switch (variable.scale.type) {
        case 'continuous':
          scale = continuousScale(variable, data);
          break;
        case 'quantile':
          scale = quantileScale(variable, data);
          break;
        case 'categorical':
          scale = categoricalScale(variable, data);
          break;
        default:
          scale = d3.scaleIdentity();
      }

      return scale;
    }
  }
};

export default mixin;
