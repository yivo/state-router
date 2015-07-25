Router.once 'start', ->
  Router.on 'transitionStart', (transition) ->
    Router.dispatchedTransition = transition

  Router.on 'transitionAbort', (transition) ->
    Router.dispatchedTransition = null
    Router.abortedTransition    = transition

  Router.on 'transitionSuccess', (transition) ->
    Router.succeedTransition    = transition
    Router.currentParams        = transition.params
    Router.currentRoute         = transition.route
    Router.dispatchedTransition = null

  Router.on 'stateEnterSuccess', (state) ->
    Router.currentState = state
    Router.notify 'stateChange', state

  Router.on 'stateLeaveSuccess', (state) ->
    Router.currentState = state.base

Router.once 'debug', ->
  Router.on 'transitionStart', (transition) ->
    console.debug "[#{Router}] Started #{transition}"
    console.debug "[#{Router}] Parameters", transition.params

  Router.on 'transitionSuccess', (transition) ->
    console.debug "[#{Router}] Succeed #{transition}"

  Router.on 'stateEnterStart', (state) ->
    console.debug "[#{Router}] Entering #{state}"

  Router.on 'stateLeaveStart', (state) ->
    console.debug "[#{Router}] Leaving #{state}"

class Dispatcher extends BaseClass

  dispatch: (transition) ->
    Router.dispatchedTransition?.abort()

    # You can prevent from transitioning in this hook, for example.
    Router.notify('transitionStart', transition)

    # Do absolutely nothing if transition was prevented.
    # You can retry transition by doing `transition.retry()`.
    return if transition.prevented

    currentState        = Router.currentState
    currentStateChain   = currentState?.chain or []
    nextState           = transition.state
    nextStateChain      = nextState?.chain or []

    enterStates         = []
    leaveStates         = []
    ignoreStates        = []

    for state in currentStateChain
      if state in nextStateChain
        if @mustReloadState(state, transition)
          leaveStates.unshift(state)
          enterStates.push(state)
        else
          ignoreStates.push(state)
      else
        leaveStates.unshift(state)

    for state in nextStateChain
      if (state not in enterStates) and (state not in ignoreStates)
        enterStates.push(state)

    while state = leaveStates.shift()
      @leaveState(state, transition)
      return if transition.aborted

    while state = enterStates.shift()
      @enterState(state, transition)
      return if transition.aborted

    Router.notify('transitionSuccess', transition)
    return

  enterState: (state, transition) ->
    Router.notify('stateEnterStart', state, transition)
    ctrlClass = Router.findController(state.controllerName, transition.params, transition)

    if ctrlClass
      rootState      = state.root
      rootCtrl       = rootState?.__controller
      parentCtrl     = state.base?.__controller
      ctrlClass      = _.beforeConstructor ctrlClass, ->
        @rootController   = rootCtrl or undefined
        @parentController = parentCtrl or undefined

      controller     = new ctrlClass(transition.params, transition)
      controller.enter?(transition.toParams, transition)

    unless transition.aborted
      state.__controller      = controller
      state.__paramsIdentity  = state.identityParams(transition.route)
      Router.notify('stateEnterSuccess', state, transition)
    return

  leaveState: (state, transition) ->
    Router.notify('stateLeaveStart', state, transition)
    controller = state.__controller
    controller?.leave?(transition.params, transition)
    unless transition.aborted
      delete state.__paramsIdentity
      delete state.__controller
      Router.notify('stateLeaveSuccess', state, transition)
    return

  mustReloadState: (state, transition) ->
    a = state.__paramsIdentity
    b = state.identityParams(transition.route)

    false == if Router.options?.reloadOnQueryChange isnt true
      _.isEqual(_.omit(a, 'query'), _.omit(b, 'query'))
    else
      _.isEqual(a, b)