Router.on 'debug', ->
  Router.on 'transitionAbort', (transition) ->
    console.debug "[#{Router}] Aborted #{transition}"

  Router.on 'transitionPrevent', (transition) ->
    console.debug "[#{Router}] Prevented #{transition}"

class Transition extends BaseClass

  @param 'fromState'
  @param 'fromParams'
  @param 'fromRoute'

  @param 'toState',   alias: 'state',   required: yes
  @param 'toParams',  alias: 'params',  required: yes
  @param 'toRoute',   alias: 'route',   required: yes

  constructor: ->
    super
    @prevented = false
    @aborted   = false

  prevent: ->
    Router.notify('transitionPrevent', this) unless @prevented
    @prevented = true
    this

  abort: ->
    Router.notify('transitionAbort', this) unless @aborted
    @aborted = true
    this

  dispatch: ->
    Router.dispatcher.dispatch(this)

  retry: ->
    @dispatch()

  toString: ->
    s  = "transition"
    s += if @fromState then " #{@fromState.name}" else ' <initial>'
    s += " -> #{@toState.name}"
    s