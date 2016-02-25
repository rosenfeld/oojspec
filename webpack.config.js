var Webpack = require('webpack');
var path = require('path');

module.exports = {
  entry: [
    __dirname + '/vendor/assets/javascripts/buster/lodash.js',
    __dirname + '/vendor/assets/javascripts/buster/samsam.js',
    __dirname + '/vendor/assets/javascripts/buster/buster-core.js',
    __dirname + '/vendor/assets/javascripts/buster/buster-event-emitter.js',
    __dirname + '/vendor/assets/javascripts/buster/bane.js',
    __dirname + '/vendor/assets/javascripts/buster/expect.js',
    __dirname + '/vendor/assets/javascripts/buster/formatio.js',
    __dirname + '/vendor/assets/javascripts/buster/html.js',
    __dirname + '/vendor/assets/javascripts/buster/referee.js',
    __dirname + '/vendor/assets/javascripts/buster/stack-filter.js',
    __dirname + '/lib/assets/javascripts/oojspec.js.coffee',
    __dirname + '/lib/assets/javascripts/oojspec/utils.js.coffee',
    __dirname + '/lib/assets/javascripts/oojspec/runner.js.coffee',
    __dirname + '/lib/assets/javascripts/oojspec/progress.js.coffee',
    __dirname + '/lib/assets/stylesheets/oojspec/progress.css',
    __dirname + '/vendor/assets/stylesheets/buster/buster-test.css'
  ],
  output: {
    path: __dirname + '/lib',
    filename: 'oojspec.js'
  },
  module: {
    loaders: [
      { test: /\.js$/, loader: 'script!' },
      { test: /oojspec\.js\.coffee/, loader: 'imports?this=>window' },
      { test: /\.coffee$/, loader: 'coffee-loader' },
      { test: /\.css$/, loader: 'style-loader!css-loader' }
    ]
  }
}
