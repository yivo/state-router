Router.loadDispatcher = ->
  @dispatcher ||= new Dispatcher(@dispatcherOptions)

class Dispatcher

  @include StrictParameters

  {beforeConstructor, extend} = _

  constructor: (options) ->
    @mergeParams(options)

  dispatch: (transition, options) ->
    Router.notify('transitionBegin', transition, options)

    if transition.isPrevented()
      return false

    nextState           = transition.toState
    currentState        = transition.fromState
    nextStateChain      = nextState?.getChain() or []
    currentStateChain   = currentState?.getChain() or []
    enterStates         = []
    leaveStates         = []
    ignoreStates        = []

    try
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
    catch error
      Router.notify('transitionError', transition, extend({}, options, {error}))
      return false

    Router.notify('transitionEnd', transition, options)
    true

  enterState: (state, transition) ->
    @_storeParams(state, state.extractBeginningParams(transition.route))

    ctrlStore = Router.loadControllerStore()
    ctrlName  = @_deriveControllerName(state, transition.toParams, transition)
    ctrlClass = ctrlName and ctrlStore.getClass(ctrlName)

    if ctrlClass
      rootState      = state.getRoot()
      rootCtrl       = rootState and @_getCtrl(rootState)
      parentCtrl     = state.base and @_getCtrl(state.base)

      ctrlClass      = beforeConstructor ctrlClass, ->
        @rootController   = rootCtrl or undefined
        @parentController = parentCtrl or undefined

      ctrl           = new ctrlClass(transition.toParams, transition)

      @_storeCtrl(state, ctrl)
      ctrl.enter?(transition.toParams, transition)

    state.notify('enter', state, transition)
    return

  leaveState: (state, transition) ->
    ctrl = @_getCtrl(state)
    @_removeParams(state)
    @_removeCtrl(state)

    ctrl?.leave?()
    state.notify('leave', state, transition)
    return

  needToReloadState: (state, transition) ->
    lastParams = @_getParams(state)
    nextParams = state.extractBeginningParams(transition.route)
    lastParams?.__version isnt nextParams?.__version

  _storeParams: (state, params) ->
    state._lastParams = params

  _storeCtrl: (state, ctrl) ->
    state._lastCtrl = ctrl

  _removeParams: (state) ->
    state._lastParams = undefined

  _removeCtrl: (state) ->
    state._lastCtrl = undefined

  _getParams: (state) ->
    state._lastParams

  _getCtrl: (state) ->
    state._lastCtrl

  _deriveControllerName: (state, params, transition) ->
    if state.hasComputedControllerName()
      state.computeControllerName(params, transition)
    else
      state.getControllerName()