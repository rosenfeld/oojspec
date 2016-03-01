oojspec._.parseParams = (search = window.location.search)->
  d = (str)-> decodeURIComponent str.replace /\+/g, ' '
  query = search.substring 1
  regex = /(.*?)=([^\&]*)&?/g
  params = {}
  params[d(m[1])] = d(m[2]) while m = regex.exec query
  params
