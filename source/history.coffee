Router.loadHistory = ->
  @history ||= new History(@historyOptions)

class History

  reFragment: /#(.*)$/

  @include PublisherSubscriber
  @include StrictParameters

  options: ->
    hashChange: yes
    interval: 50
    load: yes

  {extend, bindMethod, onceMethod, isEnabled} = _

  constructor: (options) ->
    @mergeParams(options)
    onceMethod(this, 'start')
    bindMethod(this, 'check')
    @setGlobals()
    @supportsPushState = @history?.pushState?
    @pushStateBased    = @supportsPushState and @options.pushState?
    @hashChangeBased   = !@pushStateBased

  setGlobals: ->
    @document = document? and document
    @window   = window? and window
    @location = @window?.location
    @history  = @window?.history

  start: ->
    @route = @getRoute()

    if @pushStateBased
      Router.$(@window).on('popstate', @check)
    else if 'onhashchange' of @window
      Router.$(@window).on('hashchange', @check)
    else
      setInterval(@check, @interval)

    if @options.load
      @load({@route})

  check: (e) ->
    route = @getRoute()
    if route isnt @route
      @load {route}

  load: ({route}) ->
    fixed = @_removeRouteAmbiguity(route)

    if route isnt fixed
      @navigate(fixed, replace: yes, trigger: no)
      route = fixed

    @route     = route
    fromState  = Router.currentState
    fromParams = Router.lastTransition?.toParams
    toState    = Router.stateMatcher.match(route)
    toParams   = toState?.extractParams(route) or {}
    transition = Router.createTransition {fromState, fromParams, toState, toParams, route}
    result     = Router.loadDispatcher().dispatch(transition)

    if result
      Router.currentState   = toState
      Router.lastTransition = transition
    result

  navigate: (route, options) ->
    route = @_removeRouteAmbiguity(route)

    return if @route is route

    if !options or options is true
      options = load: !!options

    result = !options.load or @load {route}

    if result
      @route = route

      if @pushStateBased
        method = if options.replace then 'replaceState' else 'pushState'
        @history[method]({}, @document.title, '/' + route)

      else
        @_updateFragment(route, options.replace)

    result

  getPath: ->
    decodeURI(@location.pathname + @location.search)

  getFragment: ->
    (@location.href.match(@reFragment)?[1] or '') + @location.search

  getRoute: (options) ->
    if @pushStateBased
      @getPath(options)
    else
      @getFragment(options)

  _updateFragment: (route, replace) ->
    route = route.replace(/\?.*$/, '')
    if replace
      href = location.href.replace(/#.*$/, '')
      location.replace(href + '#' + route)
    else
      location.hash = '#' + route
    return

  _removeRouteAmbiguity: (route) ->
    route = if '?' in route
      route.replace(/\/+\?/, '?')
    else
      route.replace(/\/+$/, '')

    route.replace(/^\/+/, '')