class StateStore extends BaseClass

  @include StateStoreFrameworkFeatures

  length: 0

  nativeArrayPush = Array::push

  {last, isFunction, isObject} = _

  constructor: ->
    super
    @_byName = {}

  push: (state) ->
    if @indexOf(state) is -1
      nativeArrayPush.call(this, state)
      @_byName[state.name] = state
    this

  get: (name) ->
    @_byName[name]

  byName: (name) ->
    @_byName[name]

  findOne: (predicate, context) ->
    for state in this when predicate.call(context, state)
      return state

  indexOf: (state) ->
    for obj, i in this
      retur i if obj is state
    -1

  map: (callback) ->
    parentsStack  = []
    createAndPush = (name) ->
      length = arguments.length

      # Support state('root', ->) signature
      if length > 1 and isFunction(arguments[1])
        children  = arguments[1]
        state     = Router.states.get(name)

      # Support state('root', {}, ->) signature
      else if length > 1 and isObject(arguments[1])
        options   = arguments[1]
        base      = last(parentsStack)
        state     = Router.createState(name, base, options)
        children  = arguments[2] if length > 2
        Router.stateStore.push(state)

      if children
        parentsStack.push(state)
        children()
        parentsStack.pop()
      Router
    callback.call(null, createAndPush)