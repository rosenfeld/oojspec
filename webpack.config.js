var ExtractTextPlugin = require("extract-text-webpack-plugin");

module.exports = {
  entry: {
    oojspec: __dirname + '/src/oojspec.js.coffee'
    , 'oojspec/iframe-runner': __dirname + '/src/oojspec/iframe-runner.js.coffee'
  }
  ,output: {
    path: __dirname + '/dist',
    filename: '[name].js'
  }
  ,module: {
    loaders: [
      { test: /buster-core\.js$/, loader: 'exports?buster!imports?require=>false' }
      , { test: /reporters\/html\.js$/, loader: 'imports?define=>false&require=>false' }
      , { test: /(oojspec|iframe-runner)\.js\.coffee/, loader: 'imports?this=>window' }
      , { test: /\.coffee$/, loader: 'coffee-loader' }
      // We must use css-loader 0.14.5 until this issue is fixed:
      // https://github.com/webpack/css-loader/issues/133
      // Otherwise the buster CSS will be compiled with wrong content for the ✓ symbol
      // (\002713)
      , { test: /\.css$/, loader: ExtractTextPlugin.extract('style', 'css?sourceMap') }
    ]
  }
  ,resolve: { alias: { expect: 'referee/lib/expect' } }
  ,devtool: 'source-map'
  ,plugins: [new ExtractTextPlugin('[name].css')]
}
