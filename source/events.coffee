console.debug = (->) unless _.isFunction(console.debug)

Router.on 'routeChange', do ->
  firstChange = true
  (route) ->
    if firstChange
      console.debug "[#{Router}] Bootstrap with route '#{route}'"
      firstChange = false
    else
      console.debug "[#{Router}] Route changed '#{route}'"

Router.on 'routeChange', (route) ->
  state = Router.stateMatcher.match(route)
  Router.transition(state, state.params(route), route)

Router.on 'fragmentUpdate', (fragment, replace) ->
  console.debug "[#{Router}] " + if replace
    "Replaced hash in history with '#{fragment}'"
  else "Set hash to history '#{fragment}'"

Router.on 'pathUpdate', (path, replace) ->
  console.debug "[#{Router}] " + if replace
    "Replaced path in history with '#{path}'"
  else "Pushed path to history '#{path}'"

Router.on 'transitionStart', (transition) ->
  action = if transition.previouslyPrevented
    'Retrying previously prevented'
  else if transition.previouslyAborted
    'Retrying previously aborted'
  else
    'Started'
  console.debug "[#{Router}] #{action} #{transition}"
  console.debug "[#{Router}] Parameters", transition.params

Router.on 'transitionAbort', (transition) ->
  console.debug "[#{Router}] Aborted #{transition}"

Router.on 'transitionPrevent', (transition) ->
  console.debug "[#{Router}] Prevented #{transition}"

Router.on 'transitionSuccess', (transition) ->
  Router.currentParams = transition.params
  Router.currentRoute  = transition.route

Router.on 'transitionSuccess', (transition) ->
  console.debug "[#{Router}] Succeed #{transition}"

Router.on 'stateEnterAbort', (state) ->
  console.debug "[#{Router}] #{_.repeat('  ', state.depth + 1)}Aborted #{state}"

Router.on 'stateEnterSuccess', (state) ->
  console.debug "[#{Router}] #{_.repeat('  ', state.depth + 1)}Succeed #{state}"

Router.on 'stateEnterSuccess', (state) ->
  Router.currentState = state
  Router.notify 'stateChange', state

Router.on 'stateEnterStart', (state) ->
  console.debug "[#{Router}] #{_.repeat('  ', state.depth)}Entering #{state}..."

Router.on 'stateLeaveAbort', (state) ->
  console.debug "[#{Router}] #{_.repeat('  ', state.depth + 1)}Aborted #{state}"

Router.on 'stateLeaveSuccess', (state) ->
  console.debug "[#{Router}] #{_.repeat('  ', state.depth + 1)}Succeed #{state}"

Router.on 'stateLeaveSuccess', (state) ->
  Router.currentState = state.base

Router.on 'stateLeaveStart', (state) ->
  console.debug "[#{Router}] #{_.repeat('  ', state.depth)}Leaving #{state}..."

Router.on 'linksInterceptor:interceptCancel', (reason) ->
  console.debug "[#{Router}] Link interception cancelled. Reason: #{reason}"

Router.on 'linksInterceptor:intercept', (route) ->
  console.debug "[#{Router}] Processing interception. Route: #{route}"
