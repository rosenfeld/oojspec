h = buster.reporters.html
h._lists = []

# original private function defined in Buster.js. Re-writing it here in CS
el = (doc, tagName, properties) ->
  e = doc.createElement(tagName)
  for prop, value of properties
    e.setAttribute prop, value if prop is "http-equiv"
    prop = "innerHTML" if prop == "text"
    e[prop] = value
  e

oldCreate = h.create # patch create
h.create = ->
  reporter = oldCreate.apply this, arguments
  reporter._lists = []
  reporter

h.contextStart = (context)->
  container = @root
  @_list.appendChild container = el(@doc, "li") if @_list
  container.appendChild el(@doc, "h2", text: context.name)
  container.appendChild @_list = el(@doc, "ul")
  @_lists.unshift @_list

# fix Buster.js time reporting
oldListen = h.listen
h.listen = (runner)->
  result = oldListen.apply this, arguments
  runner.bind this, 'suite:start': 'suiteStart'
  result

# doesn't currently exist in original reporter
h.suiteStart = -> @startedAt = new Date()

h.list = ->
  unless @_list = @_lists[0]
    @_lists.unshift @_list = el(this.doc, "ul", className: "test-results")
    @root.appendChild(@_list)
  @_list

h.contextEnd = (context)->
  @_lists.shift()
  @_list = @_lists[0]
