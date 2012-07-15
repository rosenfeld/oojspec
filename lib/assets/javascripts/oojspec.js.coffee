# =require buster/all

window.oojspec = new class OojspecRunner
  constructor: ->
    @runner = buster.create buster.eventEmitter
    @descriptions = []
    @assertions = buster.assertions
    (logFormatter = buster.create buster.format).quoteStrings = false
    @assertions.format = buster.bind logFormatter, "ascii"
    @assertions.on 'pass',    => @stats.tests++; @stats.assertions++
    @assertions.on 'failure', => @stats.tests++; @stats.failures++
    #@runner.on 'context:start', => @stats.contexts++
    @runner.on 'test:timeout', => @stats.timeouts++; @assertions.emit 'failure'
    @runner.on 'test:error', => @stats.errors++
    @runner.on 'test:deferred', => @stats.deferred++

    @stats =
      contexts: 0
      tests: 0
      assertions: 0
      errors: 0
      failures: 0
      timeouts: 0
      deferred: 0

  exposeAll: -> window.describe = @describe
  autorun: -> @runSpecs() unless @disableAutorun

  runSpecs: ->
    @reporter = buster.reporters.html.create()
    @reporter.listen @runner
    @runner.emit 'suite:start', name: "Specs"
    @runNextDescription()

  runNextDescription: =>
    (@runner.emit 'suite:end', @stats; return) unless @descriptions.length
    # TODO: think about non null contexts usage
    @descriptions.shift().run @runner, @assertions, null, @runNextDescription

  describe: (description, block)=>
    @stats.contexts++ # only root descriptions will be count
    @descriptions.push new Description(description, block)

class Description
  RESERVED = ['beforeAll', 'before', 'after', 'afterAll', 'describe', 'context',
              'example', 'it', 'specify', 'pending', 'xit']
  constructor: (@description, @block)->

  run: (@runner, @assertions, @context, @onFinish, @beforeBlocks = [], @afterBlocks = [])->
    @runner.emit 'context:start', name: @description
    @dsl = new DescribeDsl
    if c = @context
      for reserved in RESERVED
        try
          throw new Error("'#{reserved}' method is reserved for oojspec usage only") if c[reserved]
        catch e
          e.name = "syntax error"
          @runner.emit 'test:error', name: @description, error: e
          @onDescriptionFinished(e)
        c[reserved] = @dsl[reserved]
    @runAround @beforeBlocks, @afterBlocks, @onDescriptionFinished, @processDescriptionBlock

  onDescriptionFinished: (error)=>
    if error and not error.handled
      error.handled = true
      @runner.emit 'test:error', { name: 'Error running describe statements', error }
    @runner.emit 'context:end'
    @onFinish error

  runAround: (befores, afters, onFinish, block)->
    new AroundBlock(befores, afters, block).run @runner, @assertions, @context, onFinish

  processDescriptionBlock: (onFinish)=>
    context = @context or @dsl
    @block.call context, context
    @runAround @dsl._beforeAllBlocks_, @dsl._afterAllBlocks_, onFinish, (@onExamplesFinished)=>
      @runNextStep()

  runNextStep: =>
    (@onExamplesFinished(); return) unless @dsl._examples_.length
    nextStep = @dsl._examples_.shift()
    (@reportDeferred(nextStep.description); @runNextStep(); return) if nextStep.pending
    nextTick =
      if nextStep instanceof Description then => nextStep
        .run @runner, @assertions, @context, @runNextStep, @dsl._beforeBlocks_, @dsl._afterBlocks_
      else => # ExampleWithHooks
        nextStep.run @runner, @assertions, @context, @onExampleFinished
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
    container.push block

  constructor: ->
    @_beforeAllBlocks_ = []
    @_beforeBlocks_ = []
    @_afterBlocks_ = []
    @_afterAllBlocks_ = []
    @_examples_ = []
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
    @_examples_.push new ExampleWithHooks(description, @_beforeBlocks_, @_afterBlocks_, block)
  pending:   (description)=> @_examples_.push {description, pending: true}

class AroundBlock
  constructor: (@beforeBlocks, @afterBlocks, @block)->

  run: (@runner, @assertions, @context, @onFinish)->
    @runGroup @beforeBlocks, ((e)=> @onBeforeError e), (wasSuccessful)=>
      if wasSuccessful
        @runMainBlock @block, (error)=>
          @registerError error
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
    new ExampleGroupWithoutHooks(@assertions, @context, group, onFinish, onError).run()

  onBeforeError: (error)-> error.source = "before hook"; @registerError error
  onAfterError:  (error)-> error.source = "after hook";  @registerError error
  runAfterGroup: -> @runGroup @afterBlocks, ((e)=> @onAfterError e), (=> @onAfterHooks())
  onAfterHooks: -> @onFinish @error

class ExampleWithHooks extends AroundBlock
  constructor: (@description, @beforeBlocks, @afterBlocks, @block)->
  runMainBlock: (block, onFinish)-> new Example(block).run @assertions, @context, onFinish
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
  constructor: (@assertions, @context, @blocks, @onFinish, @onError)-> @nextIndex = 0

  run: ->
    @wasSuccessful = true
    setTimeout @nextTick, 0

  nextTick: =>
    (@onFinish(@wasSuccessful); return) unless @nextIndex < @blocks.length
    block = @blocks[@nextIndex++]
    new Example(block).run @assertions, @context, (error)=>
      (@wasSuccessful = false; @onError error) if error
      setTimeout @nextTick, 0

class Example
  TICK = 10 # ms
  constructor: (@exampleBlock)->

  run: (@assertions, @context, @onFinish)->
    @dsl = new ExampleDsl(@assertions.assert, @assertions.expect, @assertions.fail, \
                          @assertions.refute)
    if @context
      throw "runs and waitsFor are reserved attributes" if @context.runs or @context.waitsFor
      @context.runs = @dsl.runs
      @context.waitsFor = @dsl.waitsFor
    @tryBlock @exampleBlock, ->
      if @context
        delete @context.runs
        delete @context.waitsFor
      (@onFinish(); return) unless (@steps = @dsl._asyncQueue_).length
      @runNextAsyncStep()

  tryBlock: (block, onSuccess)->
    try
      context = @context or @dsl
      onSuccess.call this, block.call context, context
    catch error
      error = new Error(error) if typeof error is 'string'
      error.message = "'#{error.message}' in '#{block.description}'" if block.description
      @onFinish error

  runNextAsyncStep: ->
    (@onFinish(); return) unless @steps.length
    step = @steps.shift()
    if step instanceof Function
      @tryBlock step, @runNextAsyncStep
    else
      @waitsFor step...

  waitsFor: (@condition, timeout=1000, @description)->
    @deadline = timeout + new Date().getTime()
    @keepTryingCondition()

  keepTryingCondition: =>
    @tryBlock @condition, (result)->
      (@runNextAsyncStep(); return) if result
      (@onFinish {timeout: true, @description}; return) if new Date().getTime() > @deadline
      setTimeout @keepTryingCondition, TICK

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
