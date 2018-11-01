module.exports = {
  VERSION: 1,
  DRAW_MAX_AREA_KM2: 2000,
  VARIABLES: [
    {
      id: 'effect',
      label: 'Restoration Potential',
      formats: {
        text: ',.0f',
        axis: ',.1s'
      },
      scale: {
        type: 'continuous',
        transform: {
          type: 'log',
          min: 1
        }
      }
    },
    {
      id: 'delta',
      label: 'Connectivity Gain',
      formats: {
        text: ',.1f',
        axis: ',.1s'
      },
      scale: {
        type: 'continuous',
        transform: {
          type: 'log',
          min: 1
        }
      }
    },
    {
      id: 'aquatic',
      label: 'Aquatic Score',
      formats: {
        text: ',.2f',
        axis: ',.1s'
      },
      scale: {
        type: 'continuous',
        transform: {}
      }
    }
  ]
};
