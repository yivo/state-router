class Dispatcher extends CoreObject

  dispatch: (transition) ->
    work = =>
      @dispatcherTransition = transition

      # You can prevent from transitioning in this hook, for example.
      Router.notify('transitionStart', transition)

      # Do absolutely nothing if transition was prevented or aborted.
      # You can retry transition by doing `transition.retry()`.
      if transition.prevented
        @dispatcherTransition = null
        Router.notify('transitionPrevent', transition)
        return

      else if transition.aborted
        @dispatcherTransition = null
        Router.notify('transitionAbort', transition)
        return

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
        if transition.aborted
          @dispatcherTransition = null
          Router.notify('transitionAbort', transition)
          return

      while state = enterStates.shift()
        @enterState(state, transition)
        if transition.aborted
          @dispatcherTransition = null
          Router.notify('transitionAbort', transition)
          return

      @dispatcherTransition = null
      Router.notify('transitionSuccess', transition)

    if @dispatcherTransition
      @dispatcherTransition.abort()
      _.delay work
    else
      work()

    return

  enterState: (state, transition) ->
    Router.notify('stateEnterStart', state, transition)

    # You have aborted transition in `stateEnterStart` hook?
    if transition.aborted
      # Notify outer world and return.
      Router.notify('stateEnterAbort', state, transition)
      return

    ctrlClass = Router.findController(state.controllerName, transition.params, transition)

    if ctrlClass
      rootState      = state.root
      rootCtrl       = rootState?.__controller
      parentCtrl     = state.base?.__controller
      ctrlClass      = _.beforeConstructor ctrlClass, ->
        @rootController   = rootCtrl or undefined # guard for falsy values
        @parentController = parentCtrl or undefined # guard for falsy values

      controller     = new ctrlClass(transition.params, transition)
      controller.enter?(transition.toParams, transition)

    # You have aborted transition in controller?
    if transition.aborted
      # Controller has been created. We must do some cleanup.
      controller?.leave?()

      # Notify outer world.
      Router.notify('stateEnterAbort', state, transition)

    # Transition hasn't been aborted.
    else
      # Save controller into private property:
      state.__controller = controller

      # Save parameters identity into private property:
      state.__paramsIdentity = state.identityParams(transition.route)

      # Notify outer world.
      Router.notify('stateEnterSuccess', state, transition)

    return

  leaveState: (state, transition) ->
    # Notify outer world than state will be leaved.
    Router.notify('stateLeaveStart', state, transition)

    # You have aborted state leave in hook?
    if transition.aborted
      Router.notify('stateLeaveAbort', state, transition)
      return

    controller = state.__controller
    controller?.leave?(transition.params, transition)

    # You have aborted transition in controller?
    if transition.aborted
      Router.notify('stateLeaveAbort', state, transition)
      return

    # Transition hasn't been aborted.
    else
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
