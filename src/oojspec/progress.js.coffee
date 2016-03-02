require './progress.css'

new class ProgressStats
  constructor: (@eh = oojspec.events)->
    @total = @count = 0
    @eh.on 'suite:start', @createElements
    @eh.on 'oojspec:examples:add', (count)=> @total += count
    @eh.on 'test:success',  => @addSuccess '. '
    @eh.on 'test:deferred', => @addSuccess 'd '
    @eh.on 'test:failure', => @addError 'F '
    @eh.on 'test:error',   => @addError 'E '
    @eh.on 'test:timeout', => @addError 'T '

  createElements: =>
    @numericProgress = @addDivTo 'numeric-progress', document.body
    @progressBar = @addDivTo 'progress-bar', document.body
    @progress = @addDivTo 'progress', @progressBar

  addDivTo: (id, to)->
    div = document.createElement 'div'
    div.id = id
    to.appendChild div
    div

  addSuccess: (text)->
    el = @addAssertElement text
    el.className = 'deferred' if text is 'd '

  addError: (text)-> e = @addAssertElement text; e.className = @progress.className = 'fail'

  addAssertElement: (text)->
    @count++
    e = document.createElement('span')
    e.textContent = text
    @progress.appendChild e
    @progress.style.width = @count / @total * 100 + '%'
    @numericProgress.textContent = "#{@count} / #{@total}"
    e
