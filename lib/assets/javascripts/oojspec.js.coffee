# =require_self
# =require_tree ./oojspec

# avoid polluting the global namespace
# namespace for allowing us to split code in multiple files
# internal classes and functions declared in separate units should be exported to _
@oojspec = _: {}

(_ = @oojspec._).extend = (extended, extender)->
  extended[p] = v for p, v of extender when p[0] isnt '_'
