const webpack = require('webpack');

module.exports = {
  baseUrl: process.env.NODE_ENV === 'production'
    ? '/clsb-dev/'
    : '/',
  configureWebpack: {
    plugins: [
      new webpack.ProvidePlugin({
        L: 'leaflet'
      })
    ]
  }
};
