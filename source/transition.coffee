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
    if not @aborted and not @prevented
      @prevented = true
      @previouslyPrevented = true
    this

  abort: ->
    if not @aborted and not @prevented
      @aborted = true
      @previouslyAborted = true
    this

  dispatch: ->
    Router.dispatcher.dispatch(this)

  retry: ->
    @prevented = false
    @aborted   = false
    @dispatch()

  toString: ->
    s  = "transition"
    s += if @fromState then " #{@fromState.name}" else ' <initial>'
    s += " -> #{@toState.name}"
    s
