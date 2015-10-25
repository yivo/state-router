_.extend(Router, PublisherSubscriber.InstanceMembers)

Router.$ = $

Router.toString = -> 'StateRouter'

Router.start = ->
  Router.notify 'debug'
  Router.notify 'start'

Router.stop = ->
  Router.notify 'stop'

# TODO Router.url({})
Router.url = (state, params) ->
  c = if Router.history.pushStateBased then '/' else '#'
  c + Router.states.fetch(state).route(params)

Router.go = (state, params) ->
  Router.navigate(Router.url(state, params), true)

Router.replace = (state, params) ->
  Router.navigate(Router.url(state, params), load: yes, replace: yes)

Router.switch = (arg1, arg2) ->
  if typeof arg1 is 'string' or arg1 instanceof State
    state   = arg1
    params  = arg2
  else
    state   = Router.currentState
    params  = arg1
  Router.go(state, _.extend({}, Router.currentParams, params))

Router.navigate = (route, options) ->
  Router.history.navigate(route, options)

Router.transition = (state, params) ->
  fromRoute  = Router.currentRoute
  fromParams = Router.currentParams
  fromState  = Router.currentState

  toRoute    = Router.history.route
  toState    = Router.states.fetch(state)
  toParams   = _.extend(toState.params(toRoute), params)

  transition = new Transition({fromState, fromParams, fromRoute, toState, toParams, toRoute})
  transition.dispatch()

Router.controllerLookupNamespace = this

Router.controllerLookup = (name) ->
  ns = _.result(Router, 'controllerLookupNamespace')
  ns["#{name}Controller"] or ns[name] or ns["#{name.classCase()}Controller"] or ns[name.classCase()]

Router.findController = (arg) ->
  if typeof arg is 'function'
    length          = arguments.length
    rest            = Array(Math.max(length - 1, 0))
    index           = 0
    rest[index - 1] = arguments[index] while ++index < length
    Class           = arg(rest...)
  else
    Class           = Router.controllerLookup(arg)

  Class = Router.controllerLookup(Class) if typeof Class is 'string'
  Class
