# =require buster/all

_ = oojspec._

_.extend oojspec, new class OojspecRunner
  constructor: ->
    @timeout = 1000 # 1s - default timeout
    @runner = buster.create buster.eventEmitter
    @descriptions = []
    @_registerEventHandlers()
    @_initializeStats()
    @params = _.parseParams()

  _registerEventHandlers: ->
    @assertions = buster.assertions
    (logFormatter = buster.create buster.format).quoteStrings = false
    @assertions.format = buster.bind logFormatter, "ascii"
    @assertions.on 'pass',    => @stats.assertions++
    @assertions.on 'failure', => @stats.failures++
    #@runner.on 'context:start', => @stats.contexts++
    @runner.on 'test:timeout',  => @stats.timeouts++; @assertions.emit 'failure'
    @runner.on 'test:error',    => @stats.errors++
    @runner.on 'test:deferred', => @stats.deferred++
    @runner.on 'oojspec:examples:add', (count)=> @stats.tests += count

  _initializeStats: ->
    @stats =
      contexts: 0
      tests: 0
      assertions: 0
      errors: 0
      failures: 0
      timeouts: 0
      deferred: 0

  exposeAll: => window.describe = @describe
  autorun: => @runSpecs() unless @disableAutorun

  runSpecs: =>
    @reporter = buster.reporters.html.create detectCssPath: false
    @reporter.listen @runner
    d.processDsl @runner for d in @descriptions
    @runner.emit 'suite:start', name: "Specs"
    @_runNextDescription()

  _runNextDescription: =>
    (@runner.emit 'suite:end', @stats; return) unless @descriptions.length
    @descriptions.shift().run @assertions, @_runNextDescription

  describe: (description, block)=>
    @stats.contexts++ # only root descriptions will be count
    @descriptions.push new Description(description, block)

RESERVED_FOR_DESCRIPTION_DSL = ['beforeAll', 'before', 'after', 'afterAll', 'describe', 'context',
                                'example', 'it', 'specify', 'pending', 'xit']
RESERVED_FOR_EXAMPLE_DSL = ['assert', 'expect', 'fail', 'refute', 'waitsFor', 'runs']
class Description
  RESERVED = RESERVED_FOR_DESCRIPTION_DSL.concat RESERVED_FOR_EXAMPLE_DSL

  constructor: (@description, @block)->
    if @description.runSpecs or @description.prototype?.runSpecs
      @block = @description
      @description = @block.description or @block.name

  processDsl: (@runner, @binding, @bare)->
    @dsl = new DescribeDsl
    (@block.runSpecs or @block.prototype?.runSpecs) and @detectBindingError()

    @binding or= {}
    @injectDsl() unless @bare
    if @block.runSpecs or @block.prototype?.runSpecs
      @binding.runSpecs @dsl
    else
      @block.call @binding, @dsl
    @runner.emit 'oojspec:examples:add', @dsl._examplesCount_
    @removeDsl() unless @bare
    @bare or= @binding.bare

    d.processDsl @runner, @binding, @bare for d in @dsl._examples_ when d instanceof Description

  detectBindingError: ->
    try
      @binding = if @block.prototype then new @block else @block
      if @binding and not (@bare = @block.bare)
        for reserved in RESERVED when @binding[reserved]
          throw new Error("'#{reserved}' method is reserved for oojspec usage only")
    catch e
      e.name = "syntax error"
      @bindingError = e

  injectDsl: -> @binding[p] = v for p, v of @dsl; return

  removeDsl: -> delete @binding[p] for p in RESERVED_FOR_DESCRIPTION_DSL; return

  run: (@assertions, @onFinish, @beforeBlocks = [], @afterBlocks = [])->
    @runner.emit 'context:start', name: @description
    if @bindingError
      @runner.emit 'test:error', name: @description, error: @bindingError
      @onDescriptionFinished @bindingError
    else
      @doRun()

  doRun: -> @runAround @beforeBlocks, @afterBlocks, @onDescriptionFinished, @processDescriptionBlock

  onDescriptionFinished: (error)=>
    if error and not error.handled
      error.handled = true
      @runner.emit 'test:error', { name: 'Error running describe statements', error }
    @runner.emit 'context:end'
    @onFinish error

  runAround: (befores, afters, onFinish, block)->
    new AroundBlock(befores, afters, block).run @runner, @assertions, @binding, @bare, onFinish

  processDescriptionBlock: (onFinish)=>
    @runAround @dsl._beforeAllBlocks_, @dsl._afterAllBlocks_, onFinish, (@onExamplesFinished)=>
      @runNextStep()

  runNextStep: =>
    (@onExamplesFinished(); return) unless @dsl._examples_.length
    nextStep = @dsl._examples_.shift()
    (@reportDeferred(nextStep.description); @runNextStep(); return) if nextStep.pending
    nextTick =
      if nextStep instanceof Description then =>
        nextStep.run @assertions, @runNextStep, @dsl._beforeBlocks_, @dsl._afterBlocks_
      else => # ExampleWithHooks
        nextStep.run @runner, @assertions, @binding, @bare, @onExampleFinished
    setTimeout nextTick, 0

  onExampleFinished: (error)=>
    (@runNextStep(); return) unless error and not error.handled
    error.handled = true
    console.log error
    name = @description
    name += " in #{error.source}" if error.source
    @runner.emit 'test:error', { name, error }
    @onFinish(error)

  reportDeferred: (description)-> @runner.emit 'test:deferred', name: description

class DescribeDsl
  addHook = (description, block, container)->
    if typeof description is 'string'
      return unless block # pending hook
      block.description = description
    else
      block = description
    throw new Error("block missing") unless block
    container.push block

  constructor: ->
    @_beforeAllBlocks_ = []
    @_beforeBlocks_ = []
    @_afterBlocks_ = []
    @_afterAllBlocks_ = []
    @_examples_ = []
    @_examplesCount_ = 0 # only examples, not describes
    # aliases:
    @it = @specify = @example
    @context = @describe
    @xit = @pending

  beforeAll: (description, block)=> addHook description, block, @_beforeAllBlocks_
  before:    (description, block)=> addHook description, block, @_beforeBlocks_
  after:     (description, block)=> addHook description, block, @_afterBlocks_
  afterAll:  (description, block)=> addHook description, block, @_afterAllBlocks_
  describe:  (description, block)=>
    @_examples_.push new Description(description, block, @_beforeBlocks_, @_afterBlocks_)
  example:   (description, block)=>
    throw new Error("Examples must have a description and a block") unless description and block
    @_examplesCount_++
    @_examples_.push new ExampleWithHooks(description, @_beforeBlocks_, @_afterBlocks_, block)
  pending:   (description)=>
    @_examplesCount_++
    @_examples_.push {description, pending: true}

class AroundBlock
  constructor: (@beforeBlocks, @afterBlocks, @block)->

  run: (@runner, @assertions, @binding, @bare, @onFinish)->
    @runGroup @beforeBlocks, ((e)=> @onBeforeError e), (wasSuccessful)=>
      if wasSuccessful
        @runMainBlock @block, (error)=>
          @registerError error if error
          @runAfterGroup()
      else @runAfterGroup()

  registerError: (error)->
    @runner.emit 'oojspec:log:error', error
    @error or= error

  runMainBlock: (block, onFinish)->
    try
      block onFinish
    catch error
      error = new Error(error) if typeof error is 'string'
      @registerError error
      onFinish error

  runGroup: (group, onError, onFinish)->
    new ExampleGroupWithoutHooks(@assertions, @binding, @bare, group, onFinish, onError).run()

  onBeforeError: (error)-> error.source = "before hook"; @registerError error
  onAfterError:  (error)-> error.source = "after hook";  @registerError error
  runAfterGroup: -> @runGroup @afterBlocks, ((e)=> @onAfterError e), (=> @onAfterHooks())
  onAfterHooks: -> @onFinish @error

class ExampleWithHooks extends AroundBlock
  constructor: (@description, @beforeBlocks, @afterBlocks, @block)->
  runMainBlock: (block, onFinish)-> new Example(block).run @assertions, @binding, @bare, onFinish
  onAfterHooks: ->
    @handleResult()
    super

  handleResult: ->
    (@runner.emit 'test:success', name: @description; return) unless @error
    @error.handled = true
    if @error.name is 'AssertionError'
      @runner.emit 'test:failure', name: @description, error: @error
      return

    if @error.timeout
      @error.source or= 'example'
      @runner.emit 'test:timeout', name: @description, error: @error
      return
    @error.name = 'Exception'
    @error.name += " in #{@error.source}" if @error.source
    @runner.emit 'test:error', name: @description, error: @error

class ExampleGroupWithoutHooks
  constructor: (@assertions, @binding, @bare, @blocks, @onFinish, @onError)-> @nextIndex = 0

  run: ->
    @wasSuccessful = true
    setTimeout @nextTick, 0

  nextTick: =>
    (@onFinish(@wasSuccessful); return) unless @nextIndex < @blocks.length
    block = @blocks[@nextIndex++]
    new Example(block).run @assertions, @binding, @bare, (error)=>
      (@wasSuccessful = false; @onError error) if error
      setTimeout @nextTick, 0

class Example
  TICK = 10 # ms
  constructor: (@exampleBlock)-> @describeDsl = {}

  run: (@assertions, @binding, @bare, @onFinish)->
    @dsl = new ExampleDsl(@assertions.assert, @assertions.expect, @assertions.fail, \
                          @assertions.refute)
    if @binding and not @bare
      for m in RESERVED_FOR_DESCRIPTION_DSL
        @describeDsl[m] = b if b = @binding[m]
        delete @binding[m]
      (@binding[m] = b if b = @dsl[m]) for m in RESERVED_FOR_EXAMPLE_DSL
    @tryBlock @exampleBlock, ->
      if @binding and not @bare
        delete @binding.runs
        delete @binding.waitsFor
      (@finish(); return) unless (@steps = @dsl._asyncQueue_).length
      @runNextAsyncStep()

  tryBlock: (block, onSuccess)->
    try
      binding = @binding or @dsl
      onSuccess.call this, block.call(binding, @dsl)
    catch error
      error = new Error(error) if typeof error is 'string'
      error.message = "'#{error.message}' in '#{block.description}'" if block?.description
      @finish error

  runNextAsyncStep: ->
    (@finish(); return) unless @steps.length
    step = @steps.shift()
    if step instanceof Function
      @tryBlock step, @runNextAsyncStep
    else
      @waitsFor step...

  waitsFor: (@condition, timeout = @binding?.timeout or oojspec.timeout, @description)->
    @deadline = timeout + new Date().getTime()
    @keepTryingCondition()

  keepTryingCondition: =>
    @tryBlock @condition, (result)->
      (@runNextAsyncStep(); return) if result
      (@finish {timeout: true, @description}; return) if new Date().getTime() > @deadline
      setTimeout @keepTryingCondition, TICK

  finish: ->
    if @binding and not @bare
      (@binding[m] = b if b = @describeDsl[m]) for m in RESERVED_FOR_DESCRIPTION_DSL
      delete @binding[m] for m in RESERVED_FOR_EXAMPLE_DSL
    @onFinish.apply null, arguments

class ExampleDsl
  constructor: (@assert, @expect, @fail, @refute)-> @_asyncQueue_ = []

  runs: (step)=> @_asyncQueue_.push step

  waitsFor: =>
    for a in arguments
      (condition = a; continue)   if typeof a is "function"
      (timeout = a; continue)     if typeof a is "number"
      (description = a; continue) if typeof a is "string"
    @_asyncQueue_.push [condition, timeout, description]

class StepContext
  constructor: (@assert, @expect, @fail)->
