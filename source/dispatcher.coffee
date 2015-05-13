Router.loadDispatcher = ->
  @dispatcher ||= new Dispatcher(@dispatcherOptions)

class Dispatcher

  @include StrictParameters

  {beforeConstructor} = _

  constructor: (options) ->
    @mergeParams(options)
    @_paramsStore = {}

  dispatch: (transition, options) ->
    Router.notify('transitionBegin', transition, options)

    return false if transition.isPrevented()

    nextState           = transition.toState
    currentState        = transition.fromState
    nextStateChain      = nextState?.getChain() or []
    currentStateChain   = currentState?.getChain() or []
    enterStates         = []
    leaveStates         = []
    ignoreStates        = []

    for state in currentStateChain
      if state in nextStateChain
        if not @needToReloadState(state, transition)
          ignoreStates.push(state)
        else
          leaveStates.unshift(state)
          enterStates.push(state)
      else
        leaveStates.unshift(state)

    for state in nextStateChain
      if (state not in enterStates) and (state not in ignoreStates)
        enterStates.push(state)

    for state in leaveStates
      @leaveState(state, transition)

    for state in enterStates
      @enterState(state, transition)

    Router.notify('transitionEnd', transition, options)
    true

  enterState: (state, transition) ->
    @_storeParams(state, state.extractBeginningParams(transition.route))

    store     = Router.controllerStore
    ctrlName  = state.getControllerName()
    ctrlClass = ctrlName and store.getClass(ctrlName)

    if ctrlClass
      rootState      = state.getRoot()
      rootCtrlName   = rootState?.getControllerName()
      rootCtrl       = rootCtrlName and store.getInstance(rootCtrlName)
      parentCtrlName = state.base?.getControllerName()
      parentCtrl     = parentCtrlName and store.getInstance(parentCtrlName)

      ctrlClass      = beforeConstructor ctrlClass, ->
        @rootController   = rootCtrl
        @parentController = parentCtrl
      ctrl           = new ctrlClass(transition.toParams, transition)

      store.registerInstance(ctrlName, ctrl)
    return

  leaveState: (state, transition) ->
    @_removeParams(state)

    store     = Router.controllerStore
    ctrlName  = state.getControllerName()
    ctrl      = ctrlName and store.popInstance(ctrlName)
    ctrl?.destroy()?
    return

  needToReloadState: (state, transition) ->
    lastParams = @_getParams(state)
    nextParams = state.extractBeginningParams(transition.route)
    lastParams?.__version isnt nextParams?.__version

  _storeParams: (state, params) ->
    @_paramsStore[state.name] = params

  _removeParams: (state) ->
    @_paramsStore[state.name] = null

  _getParams: (state) ->
    @_paramsStore?[state.name]