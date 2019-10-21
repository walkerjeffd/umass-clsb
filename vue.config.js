const webpack = require('webpack');

module.exports = {
  baseUrl: process.env.NODE_ENV === 'production'
    ? '/aq-connectivity-tool/'
    : '/',
  configureWebpack: {
    plugins: [
      new webpack.ProvidePlugin({
        L: 'leaflet'
      })
    ]
  }
};
