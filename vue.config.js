const webpack = require('webpack');

module.exports = {
  baseUrl: '/clsb-dev/',
  configureWebpack: {
    plugins: [
      new webpack.ProvidePlugin({
        L: 'leaflet'
      })
    ]
  }
};
