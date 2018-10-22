module.exports = {
  VERSION: 1,
  VARIABLES: [
    {
      id: 'effect_ln',
      label: 'ln(Restoration Potential)',
      formats: {
        text: ',.0f',
        axis: ',.1s'
      },
      scale: {
        type: 'continuous',
        transform: {}
      }
    },
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
    }
    // {
    //   id: 'type',
    //   label: 'Barrier Type',
    //   formats: {
    //     text: null,
    //     axis: null
    //   },
    //   scale: {
    //     type: 'categorical',
    //     transform: {
    //       type: null
    //     }
    //   }
    // }
  ]
};
