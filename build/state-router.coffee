((factory) ->

  # Browser and WebWorker
  root = if typeof self is 'object' and self?.self is self
    self

  # Server
  else if typeof global is 'object' and global?.global is global
    global

  # AMD
  if typeof define is 'function' and define.amd
    define ['lodash', 'jquery', 'XRegExp', 'coffee-concerns', 'callbacks', 'construct-with', 'publisher-subscriber', 'property-accessors', 'yess', 'exports'], (_, $, XRegExpAPI, Concerns, Callbacks, ConstructWith, PublisherSubscriber, PropertyAccessors) ->
      root.StateRouter = factory(root, _, $, XRegExpAPI, Concerns, Callbacks, ConstructWith, PublisherSubscriber, PropertyAccessors)

  # CommonJS
  else if typeof module is 'object' and module isnt null and
          module.exports? and typeof module.exports is 'object'
    module.exports = factory(root, require('lodash'), require('jquery'), require('XRegExp'), require('coffee-concerns'), require('callbacks'), require('construct-with'), require('publisher-subscriber'), require('property-accessors'), require('yess'))

  # Browser and the rest
  else
    root.StateRouter = factory(root, root._, root.$, root.XRegExp, root.Concerns, root.Callbacks, root.ConstructWith, root.PublisherSubscriber, root.PropertyAccessors)

  # No return value
  return

)((__root__, _, $, XRegExpAPI, Concerns, Callbacks, ConstructWith, PublisherSubscriber, PropertyAccessors) ->
  XRegExp = XRegExpAPI.XRegExp or XRegExpAPI
  
  Router = {}
  
  do ->
    Router.property = PropertyAccessors.ClassMembers.property
    property        = (name, getter) -> Router.property(name, memo: true, readonly: true, getter)
  
    property 'history',          -> new @History(_.result(this, 'historyOptions'))
    property 'linksInterceptor', -> new @LinksInterceptor(_.result(this, 'linksInterceptorOptions'))
    property 'paramHelper',      -> new @ParamHelper(_.result(this, 'paramHelperOptions'))
    property 'pathDecorator',    -> new @PathDecorator(_.result(this, 'pathDecoratorOptions'))
    property 'patternCompiler',  -> new @PatternCompiler(_.result(this, 'patternCompilerOptions'))
    property 'stateBuilder',     -> new @StateBuilder(_.result(this, 'stateBuilderOptions'))
    property 'dispatcher',       -> new @Dispatcher(_.result(this, 'dispatcherOptions'))
    property 'stateMatcher',     -> new @StateMatcher(_.result(this, 'stateMatcherOptions'))
    property 'stateStore',       -> new @StateStore(_.result(this, 'stateStoreOptions'))
    property 'states',           -> @stateStore
  
  StateDefaultParameters =
  
    included: (Class) ->
      Class.property 'ownDefaults', readonly: true, ->
        @options.defaults?() or @options.defaults or {}
  
      Class.property 'defaults', readonly: true, ->
        state  = this
        params = {}
        while state
          defaults = state.ownDefaults
          if defaults
            for param, value of defaults
              params[param] ?= value
          state = state.base
        params
  
  StateRouteParameters =
  
    extractParams: (route) ->
      helper = Router.paramHelper
      match  = @pattern.match(route)
      params = _.extend({}, @defaults)
  
      for own param, value of match when not helper.refersToRegexMatch(param)
        if value?
          params[param] = if helper.refersToQueryString(param)
            value
          else
            # TODO Check if we need to decode param here
            helper.decode(param, value)
      params
  
    # TODO Check if we want query here?
    extractChainParams: (route) ->
      @identityParams(route)
  
    identityParams: (route) ->
      helper = Router.paramHelper
      match  = @pattern.identity(route)
      params = _.extend({}, @defaults)
  
      query         = @extractQueryString(route)
      params.query  = query if query?
  
      for own param, value of match
        if value? and not helper.refersToRegexMatch(param)
          # TODO Check if we need to decode param here
          params[param] = helper.decode(param, value)
      params
  
    extractQueryString: (route) ->
      XRegExp.exec(route, Router.patternCompiler.reQueryString)?.query
  
  StateRouteParameters.params       = StateRouteParameters.extractParams
  StateRouteParameters.chainParams  = StateRouteParameters.extractChainParams
  
  StateRouteAssemble =
  
    included: (Class) ->
      Class.param 'assembler', as: 'ownRouteAssembler'
      Class.param 'paramAssembler'
  
    paramAssembler: (params, match, optional, token, splat, param) ->
      value = params?[param] ? @defaults[param]
  
      if not value?
        unless optional
          throw "[#{Router}] Parameter '#{param}' is required to assemble #{@name} state's route"
        return ''
  
      paramHelper = Router.paramHelper
      (token or '') + if splat
        paramHelper.encodeSplat(param, value)
      else
        paramHelper.encode(param, value)
  
    assembleRoute: (params) ->
      state = this
      route = ''
      while state
        own   = state.assembleOwnRoute(params)
        route = if route
          own + (if own then '/' else '') + route
        else own
        state = state.base
  
      if (query = params?.query)?
        unless _.isString(query)
          query = decodeURIComponent(Router.$.param(query))
  
        route = route + (if query[0] is '?' then '' else '?') + query
      route
  
    assembleOwnRoute: (params) ->
      if assembler = @ownRouteAssembler
        own = assembler.call(this, _.extend({}, @ownDefaults, params), this)
      else
        path = @pattern.ownPath
        own  = Router.pathDecorator.replaceParams(path, _.bind(@paramAssembler, this, params))
      own
  
  StateRouteAssemble.route = StateRouteAssemble.assembleRoute
  
  StateStoreFrameworkFeatures = do ->
  
    Concern = {}
  
    for key, value of {Before: 0, After: 1}
      Concern['insert' + key] = do (type = key.toLowerCase(), offset = value) ->
        (state, insertedState) ->
          _state    = @get(state)
          _newState = @get(insertedState)
          i         = @indexOf(_state)
          j         = @indexOf(_newState)
  
          if i < 0
            throw new Error "[#{Router}] Can't insert #{_newState} #{type} #{_state}
              because #{_state} does not exist in store"
  
          _.removeAt(this, j) if j > -1
          _.insertAt(this, i + offset, _newState)
          this
  
    Concern
  
  Concerns.extend Router, PublisherSubscriber
  
  Router.$ = $
  
  Router.toString = -> 'StateRouter'
  
  Router.start = ->
    Router.notify 'debug'
    Router.notify 'start'
  
  Router.stop = ->
    Router.notify 'stop'
  
  # TODO Router.url({}) (same state but different params)
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
  
  # TODO Remove this shit
  Router.controllerLookupNamespace = this
  
  # TODO Remove this shit
  Router.controllerLookup = (name) ->
    ns = _.result(Router, 'controllerLookupNamespace')
    ns["#{name}Controller"] or ns[name] or ns["#{name.classCase()}Controller"] or ns[name.classCase()]
  
  # TODO Refactor
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
  
  class BaseClass
  
    @include Callbacks
    @include PropertyAccessors
    @include PublisherSubscriber
    @include ConstructWith
  
    constructor: (options) ->
      @bindCallbacks()
      @runInitializers(options)
  
  class State extends BaseClass
  
    @include StateDefaultParameters
    @include StateRouteParameters
    @include StateRouteAssemble
  
    @param 'name',       required: yes
    @param 'pattern',    required: yes
    @param 'base'
    @param '404',        as: 'handles404'
    @param 'abstract'
    @param 'controller', as: 'controllerName'
  
    constructor: ->
      super
      @id         = _.generateID()
      @handles404 = !!@handles404
      @abstract   = !!@abstract
      @isRoot     = !@base
  
      if @abstract and @handles404
        throw new Error "[#{Router}] State can't handle 404 errors
          and be abstract at the same time"
  
      if @pattern.regexBased and not @ownRouteAssembler
        throw new Error "[#{Router}] To assemble #{@name} state's route from pattern which
          is based on regex you must define custom assembler"
  
    toString: ->
      "state #{@name}"
  
    @property 'root', ->
      state = this
  
      loop
        break if not state.base
        state = state.base
  
      if state isnt this
        state
  
    @property 'chain', ->
      chain = [this]
      state = this
      while state = state.base
        chain.unshift(state)
      chain
  
    @property 'depth', ->
      depth = 0
      state = this
      ++depth while state = state.base
      depth
  
  class StateStore extends BaseClass
  
    @include StateStoreFrameworkFeatures
  
    length: 0
  
    constructor: ->
      super
      @_byName = {}
  
    push: (state) ->
      if @indexOf(state) is -1
        Array::push.call(this, state)
        @_byName[state.name] = state
      this
  
    get: (state) ->
      if _.isObject(state) then state else @_byName[state]
  
    fetch: (state) ->
      _state = @get(state)
  
      unless _state
        throw new Error "[#{Router}] State #{state} does not exist!"
  
      _state
  
    findOne: (predicate, context) ->
      for state in this when predicate.call(context, state)
        return state
  
    indexOf: (state) ->
      _state = @get(state)
      for obj, i in this
        return i if obj is _state
      -1
  
    draw: (callback) ->
      parentsStack  = []
      thisApi       = (name) ->
        length = arguments.length
  
        # Support state('root', ->) signature
        if length > 1 and _.isFunction(arguments[1])
          children  = arguments[1]
          state     = Router.states.get(name)
  
        # Support state('root', {}, ->) signature
        else if length > 1 and _.isObject(arguments[1])
          options   = arguments[1]
          base      = _.last(parentsStack)
          state     = Router.createState(name, base, options)
          children  = arguments[2] if length > 2
          Router.stateStore.push(state)
  
        if children
          parentsStack.push(state)
          children()
          parentsStack.pop()
        Router
      callback(thisApi)
  
  class StateBuilder extends BaseClass
  
    build: (name, base, data) ->
      if base
        name = base.name + '.' + name
        basePattern = base.pattern
  
      if data['404'] and !data.pattern? and !data.path
        data.pattern = '.*'
  
      pattern = if data.pattern?
        Pattern.fromRegexSource(data.pattern, base: basePattern)
  
      else if data.path?
        Pattern.fromPath(data.path, base: basePattern)
  
      else
        throw new Error "[#{Router}] Neither path nor pattern specified for state #{name}"
  
      extend data, {name, base, pattern}
  
      new State(data)
  
    {extend} = _
  
  {isObject, isString} = _
  
  Router.createState = (name) ->
    length  = arguments.length
    base    = arguments[1] if length > 1
  
    if isObject(base) and base not instanceof State
      options = base
      base    = null
    else
      base    = Router.states.get(base) if isString(base)
      options = arguments[2] if length > 2
  
    Router.stateBuilder.build(name, base, options)
  
  class StateMatcher extends BaseClass
  
    match: (route) ->
      states = Router.states
  
      match = states.findOne (state) ->
        !state.abstract and !state.handles404 and state.pattern.test(route)
  
      match ||= states.findOne (state) ->
        state.handles404
  
      unless match
        throw new Error "[#{Router}] None of states matched route '#{route}' and no 404 state was found"
  
      match
  
  class Pattern extends BaseClass
  
    @param 'base'
    @param 'source', as: 'ownSource', required: yes
    @param 'path',   as: 'ownPath'
  
    constructor: ->
      super
      @source =
        if baseSource = @base?.source
          baseSource + if @ownSource then ('/' + @ownSource) else ''
        else
          @ownSource
  
      @type             = if @ownPath? then 'path' else 'regex'
      @regexBased       = @type is 'regex'
      @pathBased        = @type is 'path'
      compiler          = Router.patternCompiler
      @reRoute          = compiler.compile(@source, starts: yes, ends: yes)
      @reRouteIdentity  = compiler.compile(@source, starts: yes, ends: no)
  
    test: (route) ->
      @reRoute.test(route)
  
    match: (route) ->
      XRegExp.exec(route, @reRoute)
  
    identity: (route) ->
      XRegExp.exec(route, @reRouteIdentity)
  
    {extend} = _
  
    @fromPath: (path, options) ->
      decorator = Router.pathDecorator
      source    = decorator.preprocessParams(decorator.escape(path))
      @fromRegexSource(source, extend({}, options, {path}))
  
    @fromRegexSource: (source, options) ->
      new this(extend({}, options, {source}))
  
  class PatternCompiler extends BaseClass
  
    rsQueryString:  '(?:\\?(?<query>([\\s\\S]*)))?'
    reQueryString:  XRegExp(this::rsQueryString + '$')
    leftBoundary:   '^'
    rightBoundary:  this::rsQueryString + '$'
  
    {isEnabled} = _
  
    compile: (source, options) ->
      XRegExp(@bound(source, options))
  
    bound: (source, options) ->
      starts = isEnabled(options, 'starts')
      ends   = isEnabled(options, 'ends')
      empty  = source is ''
  
      if starts
        source = @leftBoundary + source
  
        if empty and not ends
          source = source + @rsQueryString
  
      if ends
        source = source + @rightBoundary
  
      source
  
  # TODO Bugs with splat param
  class PathDecorator extends BaseClass
  
    @params 'paramPreprocessor', 'reEscape', 'escapeReplacement'
  
    reEscape:           /[\-{}\[\]+?.,\\\^$|#\s]/g
    reParam:            /(\()?(.)?(\*)?:(\w+)\)?/g
    escapeReplacement:  '\\$&'
  
    paramPreprocessor: (match, optional, token, splat, param) ->
      ret = "(?:#{token || ''}(?<#{param}>" + (if splat then '[^?]*?' else '[^/?]+') + '))'
      if optional then "(?:#{ret})?" else ret
  
    # @example Required param
    #   Path:    blog/post/:id
    #   XRegExp: blog\/post\/(?<id>[^\/?]+)
    #   RegExp:  blog\/post\/([^\/?]+)
    #
    # @example Optional param
    #   Path:    users(/:searchConditions)
    #   Steps:
    #     1) Optional segment: users(?:/:searchConditions)?
    #     2) Parameter:        users(?:/(?<searchConditions>[^/?]+))?
    #   XRegExp: users(?:/(?<searchConditions>[^/?]+))?
    #   RegExp:  users(?:\/([^\/?]+))?
    #
    # @example Required splat param
    #   Path:    download/*:filepath
    #   XRegExp: download/(?<filepath>[^?]*?)
    #   RegExp:  download\/([^?]*?)
    #
    # @example Optional splat param
    #   Path:    directory/view/root(/*:path)
    #   Steps:
    #     1) Optional segment: directory/view/root(?:/*:path)?
    #     2) Parameter:        directory/view/root(?:/(?<path>[^?]*?))?
    #   XRegExp: directory/view/root(?:/(?<path>[^?]*?))?
    #   RegExp:  directory\/view\/root(?:\/([^?]*?))?
    preprocessParams: (path) ->
      @replaceParams(path, @paramPreprocessor)
  
    replaceParams: (path, replacement) ->
      path.replace(@reParam, replacement)
  
    escape: (path) ->
      path.replace(@reEscape, @escapeReplacement)
  
  class Dispatcher extends BaseClass
  
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
  
  class ParamHelper extends BaseClass
  
    reArrayIndex: /^[0-9]+$/
  
    refersToRegexMatch: (param) ->
      @reArrayIndex.test(param) or param in ['index', 'input']
  
    refersToQueryString: (param) ->
      param is 'query'
  
    encode: (param, value) ->
      encodeURIComponent(value)
  
    encodeSplat: (param, value) ->
      encodeURI(value)
  
    decode: (param, value) ->
      decodeURIComponent(value)
  
  class Transition extends BaseClass
  
    @param 'fromState'
    @param 'fromParams'
    @param 'fromRoute'
  
    @param 'toState',   alias: 'state',   required: yes
    @param 'toParams',  alias: 'params',  required: yes
    @param 'toRoute',   alias: 'route',   required: yes
  
    constructor: ->
      super
      @prevented = false
      @aborted   = false
  
    prevent: ->
      if not @aborted and not @prevented
        @prevented = true
        @previouslyPrevented = true
      this
  
    abort: ->
      if not @aborted and not @prevented
        @aborted = true
        @previouslyAborted = true
      this
  
    dispatch: ->
      Router.dispatcher.dispatch(this)
  
    retry: ->
      @prevented = false
      @aborted   = false
      @dispatch()
  
    toString: ->
      s  = "transition"
      s += if @fromState then " #{@fromState.name}" else ' <initial>'
      s += " -> #{@toState.name}"
      s
  
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
  
  Router.on 'start', ->
    Router.linksInterceptor.start()
  
  Router.on 'stop', ->
    Router.linksInterceptor.stop()
  
  Router.reURIScheme      = /^(\w+):(?:\/\/)?/
  Router.reJavaScriptURI  = /^\s*javascript:(.*)$/
  Router.reAnchorURI      = /^\s*(#.*)$/
  
  Router.matchURIScheme = (str) ->
    str?.match?(Router.reURIScheme)?[0]
  
  class LinksInterceptor extends BaseClass
  
    constructor: ->
      super
      _.bindMethod(this, 'intercept')
      @started = false
  
    start: ->
      if @started
        throw new Error "[#{Router}] Links interceptor has already been started!"
  
      @$document  = Router.$(document)
  
      @$document.on('click.LinksInterceptor', 'a', @intercept)
      @started = true
      this
  
    stop: ->
      unless @started
        throw new Error "[#{Router}] Links interceptor hasn't been started!"
  
      @$document.off('.LinksInterceptor')
      @started = false
      this
  
    intercept: (e) ->
      # Only intercept left-clicks
      if e.which isnt 1
        Router.notify 'linksInterceptor:interceptCancel',
                      'Only left-clicks are intercepted.'
        return
  
      # Allow action "Open in new tab" (CTRL + Left click or Command + Left click)
      # http://stackoverflow.com/questions/20087368/how-to-detect-if-user-it-trying-to-open-a-link-in-a-new-tab
      #
      # e.metaKey checks Apple Keyboard
      # e.button checks middle click, > IE9 + Everyone else
      if e.ctrlKey or e.shiftKey or e.metaKey or e.button? is 1
        Router.notify 'linksInterceptor:interceptCancel',
                      'Links are not intercepted when key is pressed. This allows user to open link in new tab.'
        return
  
      $link = Router.$(e.currentTarget)
  
      # Get the href
      # Stop processing if there isn't one
      unless href = $link.attr('href')
        Router.notify 'linksInterceptor:interceptCancel',
                      "Link is missing href attribute or it's value is blank."
        return
  
      if Router.reJavaScriptURI.test(href)
        Router.notify 'linksInterceptor:interceptCancel',
                      'URI contains javascript: expression.'
        return
  
      if Router.history.pushChangeBased and Router.reAnchorURI.test(href)
        Router.notify 'linksInterceptor:interceptCancel',
                      'Anchor URIs are not intercepted.'
        return
  
      # Determine if we're supposed to bypass the link
      # based on it's attributes
      intercept = $link.attr('intercept') ? $link.data('intercept')
      if intercept in ['false', false]
        Router.notify 'linksInterceptor:interceptCancel',
                      "Link interception bypassed based on it's attribute."
        return
  
      # Return if the URI is absolute, or if URI contains scheme
      if Router.reURIScheme.test(href)
        Router.notify 'linksInterceptor:interceptCancel',
                      'Absolute URI or URI with scheme are not intercepted.'
        return
  
      # If we haven't been stopped yet, then we prevent the default action
      e.preventDefault()
  
      route = if Router.history.pushStateBased
        History.derivePath($link[0])
      else
        History.deriveFragment($link[0])
  
      Router.notify('linksInterceptor:intercept', route)
  
      Router.navigate(route, true)
      return
  
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
  
  
  _.extend Router, {
    State
    StateStore
    StateBuilder
    StateDefaultParameters
    StateRouteParameters
    StateRouteAssemble
    StateStoreFrameworkFeatures
    Dispatcher
    History
    PathDecorator
    PatternCompiler
    StateMatcher
    Transition
    Pattern
    ParamHelper
    LinksInterceptor
  }
  
  Router
  
)