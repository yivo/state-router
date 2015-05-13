Router.loadStateStore = ->
  @stateStore ||= new StateStore(@stateStoreOptions)

class StateStore

  @include StrictParameters

  length: 0

  arrayPush = Array::push

  constructor: (options) ->
    @mergeParams(options)
    @_byName = {}

  push: (state) ->
    arrayPush.call(this, state)
    @_byName[state.getName()] = state
    this

  get: (name) ->
    @_byName[name]

  findOne: (predicate, context) ->
    for state in this when predicate.call(context, state)
      return state