module.exports = {
  VERSION: 1,
  VARIABLES: [
    {
      id: 'effect',
      label: 'Connectivity Effect',
      formats: {
        text: ',.1f',
        axis: ',.1s'
      },
      transform: {
        type: 'pow',
        exponent: 0.1
      }
    },
    {
      id: 'delta',
      label: 'Connectivity Delta',
      formats: {
        text: ',.1f',
        axis: ',.1s'
      },
      transform: {
        type: 'pow',
        exponent: 0.1
      }
    },
    {
      id: 'type',
      label: 'Barrier Type',
      formats: {
        text: null,
        axis: null
      },
      transform: {
        type: null
      }
    },
  ]
};
