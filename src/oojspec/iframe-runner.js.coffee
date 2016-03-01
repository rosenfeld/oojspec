extend = (extended, extender)-> extended[p] = v for p, v of extender when p[0] isnt '_'

@oojspec or= new class IFrameOojspec
  constructor: (@_oojspec = parent.oojspec)->
    @_originalAssertions_ = @_oojspec.assertions
    extend (@assertions = {}), @_originalAssertions_
    @_deferredCalls_ = []
    for m in ['describe', 'notify', 'on']
      this[m] = do (m)=> => @_deferredCalls_.push [m, arguments]

  run: ->
    @_oojspec.on 'iframe-start', (w)=> @_oojspec.assertions = @assertions if w is window
    @_oojspec.on 'iframe-end', (w)=> @_oojspec.assertions = @_originalAssertions_ if w is window
    @_oojspec.notify 'iframe-start', window
    @_oojspec[method] args... for [method, args] in @_deferredCalls_
    @_oojspec.notify 'iframe-end', window

  exposeAll: -> window.describe = @describe
