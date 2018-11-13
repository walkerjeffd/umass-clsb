module.exports = {
  VERSION: 1,
  DRAW_MAX_AREA_KM2: 2000,
  LOCALSTORAGE_PROJECT_KEY: 'clsb-project',
  MAX_SCENARIOS: 2000,
  BATCH_CHUNK_SIZE: 10,
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
      description: 'Incoporates both the change in aquatic connectivity (Connectivity Gain) and habitat quality (as expressed by an Index of Ecological Integrity).',
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
      description: 'Change in aquatic connectedness resulting from crossing replacement or dam removal based on the Critical Linkages\' resistant kernel approach.',
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
      description: 'Degree to which crossing is passable based either on NAACC assessments (surveyed crossings) or the Critical Linkages assessment model (unsurveyed crossings). Dams are assumed to have a value of zero (impassable).',
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
