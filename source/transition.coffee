Router.createTransition = (options) ->
  new Transition(options)

class Transition

  @include StrictParameters

  @param 'fromState'
  @param 'toState',  required: yes
  @param 'fromParams'
  @param 'toParams', alias: 'params'
  @param 'route',    required: yes

  constructor: (options) ->
    @mergeParams(options)

  prevent: ->
    @_prevented = yes

  isPrevented: ->
    !!@_prevented