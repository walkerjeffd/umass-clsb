module.exports = {
  VERSION: 1,
  DRAW_MAX_AREA_KM2: 2000,
  LOCALSTORAGE_PROJECT_KEY: 'clsb-project',
  REGION_TYPES: [
    {
      text: 'Watershed (HUC8)',
      value: 'huc8'
    },
    {
      text: 'Draw Polygon',
      value: 'draw'
    }
  ],
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
      label: 'Aquatic Passability',
      formats: {
        text: ',.2f',
        axis: ',.1s'
      },
      scale: {
        type: 'continuous',
        transform: {},
        reverse: true
      }
    }
  ]
};
