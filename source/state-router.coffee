_.extend(Router, PublisherSubscriber.InstanceMembers)

Router.$ = $

Router.toString = -> 'StateRouter'

Router.start = ->
  Router.notify 'debug'
  Router.notify 'start'

Router.stop = ->
  Router.notify 'stop'

Router.url = (state, params) ->
  c = if Router.history.pushStateBased then '/' else '#'
  c + Router.states.fetch(state).route(params)

Router.go = (state, params) ->
  Router.navigate(Router.url(state, params), true)

Router.switch = (state, params) ->
  Router.go(state, _.extend({}, Router.currentParams, params))

Router.navigate = (route, options) ->
  Router.history.navigate(route, options)

Router.transition = (state, params) ->
  fromState  = Router.currentState
  fromParams = Router.currentParams
  fromRoute  = Router.currentRoute
  toState    = Router.states.fetch(state)
  toParams   = params || {}
  toRoute    = Router.history.route

  transition = new Transition({fromState, fromParams, fromRoute, toState, toParams, toRoute})
  transition.dispatch()

Router.controllerLookupNamespace = this

Router.controllerLookup = (name) ->
  ns = _.result(Router, 'controllerLookupNamespace')
  ns["#{name}Controller"] or ns[name] or ns["#{name.classCase()}Controller"] or ns[name.classCase()]

Router.findController = (arg, rest...) ->
  Class = if _.isFunction(arg) then arg(rest...)
  else Router.controllerLookup(arg)

  Class = Router.controllerLookup(Class) if _.isString(Class)
  Class