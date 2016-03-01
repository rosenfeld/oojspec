module.exports = {
  entry: {
    oojspec: __dirname + '/src/oojspec.js.coffee'
    , 'oojspec/iframe-runner': __dirname + '/src/oojspec/iframe-runner.js.coffee'
  }
  ,output: {
    path: __dirname + '/lib/assets/javascripts',
    filename: '[name].js'
  }
  ,module: {
    loaders: [
      { test: /buster-core\.js$/, loader: 'exports?buster!imports?require=>false' }
      , { test: /reporters\/html\.js$/, loader: 'imports?define=>false&require=>false' }
      , { test: /(oojspec|iframe-runner)\.js\.coffee/, loader: 'imports?this=>window' }
      , { test: /\.coffee$/, loader: 'coffee-loader' }
      //, { test: /\.css$/, loader: 'style-loader!css-loader' }
    ]
  }
  ,resolve: { alias: { expect: 'referee/lib/expect' } }
  ,devtool: 'source-map'
}
