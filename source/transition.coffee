Router.createTransition = (options) ->
  new Transition(options)

class Transition

  @include StrictParameters

  @param 'fromState'
  @param 'toState', required: yes
  @param 'route',   required: yes
  @params 'fromParams'

  constructor: (options) ->
    @mergeParams(options)

  prevent: ->
    @_prevented = yes

  isPrevented: ->
    !!@_prevented