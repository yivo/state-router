class StateStore extends BaseClass

  @include StateStoreFrameworkFeatures

  length: 0

  constructor: ->
    super
    @_byName = {}

  push: (state) ->
    if @indexOf(state) is -1
      Array::push.call(this, state)
      @_byName[state.name] = state
    this

  get: (state) ->
    if _.isObject(state) then state else @_byName[state]

  fetch: (state) ->
    _state = @get(state)

    unless _state
      throw new Error "[#{Router}] State #{state} does not exist!"

    _state

  findOne: (predicate, context) ->
    for state in this when predicate.call(context, state)
      return state

  indexOf: (state) ->
    _state = @get(state)
    for obj, i in this
      return i if obj is _state
    -1

  draw: (callback) ->
    parentsStack  = []
    thisApi       = (name) ->
      length = arguments.length

      # Support state('root', ->) signature
      if length > 1 and _.isFunction(arguments[1])
        children  = arguments[1]
        state     = Router.states.get(name)

      # Support state('root', {}, ->) signature
      else if length > 1 and _.isObject(arguments[1])
        options   = arguments[1]
        base      = _.last(parentsStack)
        state     = Router.createState(name, base, options)
        children  = arguments[2] if length > 2
        Router.stateStore.push(state)

      if children
        parentsStack.push(state)
        children()
        parentsStack.pop()
      Router
    callback(thisApi)