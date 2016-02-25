var Webpack = require('webpack');
var path = require('path');

module.exports = {
  entry: [
    __dirname + '/lib/assets/javascripts/oojspec/iframe-runner.js.coffee',
  ],
  output: {
    path: __dirname + '/lib',
    filename: 'oojspec-iframe-runner.js'
  },
  module: {
    loaders: [
      { loader: 'imports?this=>window' },
      { loader: 'coffee-loader' },
    ]
  }
}
