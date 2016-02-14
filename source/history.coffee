Router.on 'start', ->
  _.delay -> Router.history.start()

Router.on 'stop', ->
  _.delay -> Router.history.stop()

class History extends BaseClass

  @derivePath = (obj) ->
    decodeURI((obj.pathname + obj.search).replace(/%25/g, '%2525')).replace(/^\/+/, '')

  @deriveFragment = (obj) ->
    (obj.href.match(/#(.*)$/)?[1] or '') + obj.search

  @normalizeRoute = (route) ->
    pre = if '?' in route
      route.replace(/\/+\?/, '?')
    else
      route.replace(/\/+$/, '')
    pre.replace(/^(\/|#)+/, '')

  constructor: ->
    @options            = {}
    @options.load       = true
    @options.interval   = 50

    super
    _.onceMethod(this, 'start')
    _.bindMethod(this, 'check')

    @document           = document? and document
    @window             = window? and window
    @location           = @window?.location
    @history            = @window?.history
    @supportsPushState  = @history?.pushState?
    @supportsHashChange = 'onhashchange' of @window
    @pushStateBased     = @supportsPushState and @options.pushState isnt false
    @hashChangeBased    = not @pushStateBased and @supportsHashChange and @options.hashChange isnt false
    @started            = false

  @property 'path', readonly: true, ->
    @constructor.derivePath(@location)

  @property 'fragment', readonly: true, ->
    @constructor.deriveFragment(@location)

  @property 'route', readonly: true, ->
    if @pushStateBased then @path else @fragment

  @property 'length', readonly: true, ->
    @history.length

  start: ->
    @ensureNotStarted()

    if @pushStateBased
      Router.$(@window).on('popstate', @check)
    else if @hashChangeBased
      Router.$(@window).on('hashchange', @check)
    else
      @_intervalId = setInterval(@check, @options.interval)

    @started = true
    @load(@route) if @options.load
    this

  stop: ->
    @ensureStarted()
    Router.$(@window).off('popstate', @check)
    Router.$(@window).off('hashchange', @check)
    if @_intervalId
      clearInterval(@_intervalId)
      @_intervalId = null
    @started = false
    this

  check: (e) ->
    if @ensureStarted() and @route isnt @loadedRoute
      @load(@route)
    this

  load: (route) ->
    @ensureStarted()
    normalized = @constructor.normalizeRoute(route)

    if route isnt normalized
      return @navigate(normalized, replace: yes, load: yes)

    @loadedRoute = route
    Router.notify('routeChange', route)
    true

  navigate: (route, options) ->
    @ensureStarted()

    route = @constructor.normalizeRoute(route)

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
    @history[method]({}, @document.title, '/' + route)
    Router.notify('pathUpdate', route, replace)
    return

  _updateFragment: (route, replace) ->
    # TODO Fix this
    route = route.replace(/\?.*$/, '')

    if replace
      href = @location.href.replace(/(javascript:|#).*$/, '')
      @location.replace(href + '#' + route)
    else
      @location.hash = '#' + route

    Router.notify('fragmentUpdate', replace)
    return

  ensureStarted: ->
    unless @started
      throw new Error "[#{Router}] History hasn't been started!"
    true

  ensureNotStarted: ->
    if @started
      throw new Error "[#{Router}] History has already been started!"
    true
