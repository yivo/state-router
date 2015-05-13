Router.createState = (options) ->
  new State(options)

class State

  @include PublisherSubscriber
  @include StrictParameters
  @include StateDefaultsAccess
  @include StateParametersExtract
  @include StateRouteAssemble

  @param 'name',       as: '_name', required: yes
  @param 'pattern',    required: yes
  @param 'base'
  @param 'assembler',  as: '_customAssembler'
  @param 'controller', as: '_controllerName'
  @param 'defaults',   as: '_defaultParams'
  @param '404',        as: '_404'
  @param 'abstract',   as: '_abstract'

  {bindMethod, extend} = _

  constructor: (options) ->
    @mergeParams(options)
    bindMethod(this, 'paramAssembler')
    if @isAbstract() and @is404()
      throw new Error('State can be either abstract or 404 or none')

  getName: ->
    @_name

  getControllerName: ->
    @_controllerName

  isAbstract: ->
    !!@_abstract

  is404: ->
    !!@_404

  isRoot: ->
    !@base

  getRoot: ->
    state = this

    loop
      break if not state.base
      state = state.base

    if state isnt this
      state

  getChain: ->
    chain = [this]
    state = this
    while state = state.base
      chain.unshift(state)
    chain