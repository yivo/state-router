class History extends BaseClass

  reFragment: /#(.*)$/

  options: ->
    hashChange: yes
    load:       yes
    interval:   50

  {extend, bindMethod, onceMethod, isEnabled} = _

  constructor: ->
    super
    onceMethod(this, 'start')
    bindMethod(this, 'check')

    @document           = document? and document
    @window             = window? and window
    @location           = @window?.location
    @history            = @window?.history
    @supportsPushState  = @history?.pushState?
    @pushStateBased     = @supportsPushState and @options?.pushState?
    @hashChangeBased    = !@pushStateBased
    @hasStarted         = false

  @property 'path', ->
    decodeURI((@location.pathname + @location.search).replace(/%25/g, '%2525')).replace(/^\/+/, '')

  @property 'fragment', ->
    (@location.href.match(@reFragment)?[1] or '') + @location.search

  @property 'route', ->
    if @pushStateBased then @path else @fragment

  start: ->
    unless @hasStarted
      if @pushStateBased
        Router.$(@window).on('popstate', @check)
      else if 'onhashchange' of @window
        Router.$(@window).on('hashchange', @check)
      else
        @_intervalId = setInterval(@check, @interval)

      @hasStarted = true
      @load(@route) if @options.load
    this

  stop: ->
    if @hasStarted
      Router.$(@window).off('popstate', @check)
      Router.$(@window).off('hashchange', @check)
      if @_intervalId
        clearInterval(@_intervalId)
        @_intervalId = null
      @hasStarted = false
    this

  check: (e) ->
    if @hasStarted and @route isnt @loadedRoute
      @load(@route)
    this

  load: (route) ->
    if @hasStarted
      fixed = @removeRouteAmbiguity(route)

      if route isnt fixed
        return @navigate(fixed, replace: yes, load: yes)

      @loadedRoute = route
      @notify('load', this, route)
      true
    else false

  navigate: (route, options) ->
    route = @removeRouteAmbiguity(route)

    if route isnt @loadedRoute
      @loadedRoute = route

      if !options or options is true
        options = load: !!options

      if @pushStateBased
        @_updatePath(route, options.replace)
      else
        @_updateFragment(route, options.replace)

      !options.load or @load(route)

    else false

  _updatePath: (route, replace) ->
    method = if replace then 'replaceState' else 'pushState'
    console.debug "#{method} #{route}"
    @history[method]({}, @document.title, '/' + route)

  _updateFragment: (route, replace) ->
    route = route.replace(/\?.*$/, '')
    if replace
      href = location.href.replace(/#.*$/, '')
      location.replace(href + '#' + route)
    else
      location.hash = '#' + route
    return

  removeRouteAmbiguity: (route) ->
    route = if '?' in route
      route.replace(/\/+\?/, '?')
    else
      route.replace(/\/+$/, '')

    route = route.replace(/^(\/|#)+/, '')