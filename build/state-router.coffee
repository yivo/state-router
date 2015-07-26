((root, factory) ->
  if typeof define is 'function' and define.amd
    define ['lodash', 'jquery', 'XRegExp', 'construct-with', 'publisher-subscriber', 'property-accessors', 'yess', 'ize', 'coffee-concerns'], (_, $, XRegExpAPI, ConstructWith, PublisherSubscriber, PropertyAccessors) ->
      root.StateRouter = factory(root, _, $, XRegExpAPI, ConstructWith, PublisherSubscriber, PropertyAccessors)
  else if typeof module is 'object' && typeof module.exports is 'object'
    module.exports = factory(root, require('lodash'), require('jquery'), require('XRegExp'), require('construct-with'), require('publisher-subscriber'), require('property-accessors'), require('yess'), require('ize'), require('coffee-concerns'))
  else
    root.StateRouter = factory(root, root._, root.$, root.XRegExp, root.ConstructWith, root.PublisherSubscriber, root.PropertyAccessors)
  return
)(this, (__root__, _, $, XRegExpAPI, ConstructWith, PublisherSubscriber, PropertyAccessors) ->
  XRegExp = XRegExpAPI.XRegExp or XRegExpAPI
  
  Router = {}
  
  do ->
    names = 'history linksInterceptor paramHelper
      pathDecorator patternCompiler stateBuilder
      dispatcher stateMatcher stateStore'
  
    define = (name) ->
      keyName   = "_#{name}"
      loadName  = "load#{name.capitalize()}"
      className = name.classCase()
  
      Router[loadName] = ->
        Router[keyName] ||= new Router[className](_.result(Router, "#{name}Options"))
  
      PropertyAccessors.property(Router, name, readonly: yes, get: loadName)
  
    define(name) for name in names.split(/\s+/)
  
    PropertyAccessors.property(Router, 'states', readonly: yes, get: 'loadStateStore')
    return
  
  StateDefaultParameters =
  
    included: (Class) ->
      Class.param 'defaults', as: '_ownDefaults'
  
      Class.property 'ownDefaults', ->
        if _.isFunction(@_ownDefaults)
          @_ownDefaults = @_ownDefaults()
  
        unless _.isObject(@_ownDefaults)
          @_ownDefaults = {}
  
        @_ownDefaults
  
      Class.property 'defaults', ->
        state = this
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
  
    identityParams: (route) ->
      helper = Router.paramHelper
      match  = @pattern.identity(route)
      params = _.extend({}, @defaults)
      params.query = @extractQueryString(route)
  
      for own param, value of match
        if value? and not helper.refersToRegexMatch(param)
          # TODO Check if we need to decode param here
          params[param] = helper.decode(param, value)
      params
  
    extractQueryString: (route) ->
      XRegExp.exec(route, Router.patternCompiler.reQueryString)?.query
  
  StateRouteParameters.params = StateRouteParameters.extractParams
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
      route = @base?.assembleRoute(params) or ''
      own   = @assembleOwnRoute(params)
      route = if route
        route + (if own then '/' else '') + own
      else own
  
      if query = params?.query?
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
  class BaseClass
  
    @include ConstructWith
  
    constructor: (options) ->
      @constructWith(options)
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
      @id         = _.generateId()
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
  
    map: (callback) ->
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
  
      _.extend data, {name, base, pattern}
  
      new State(data)
  
  Router.createState = (name) ->
    length  = arguments.length
    base    = arguments[1] if length > 1
  
    if _.isPlainObject(base)
      options = base
      base    = null
    else
      base    = Router.states.get(base) if _.isString(base)
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
    @param 'source', as: 'source', required: yes
    @param 'path',   as: 'ownPath'
  
    {extend} = _
  
    constructor: ->
      super
  
      if baseSource = @base?.source
        @source = baseSource + if @source then ('/' + @source) else ''
  
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
    #
    preprocessParams: (path) ->
      @replaceParams(path, @paramPreprocessor)
  
    replaceParams: (path, replacement) ->
      path.replace(@reParam, replacement)
  
    escape: (path) ->
      path.replace(@reEscape, @escapeReplacement)
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
  Router.on 'debug', ->
    Router.on 'transitionAbort', (transition) ->
      console.debug "[#{Router}] Aborted #{transition}"
  
    Router.on 'transitionPrevent', (transition) ->
      console.debug "[#{Router}] Prevented #{transition}"
  
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
      Router.notify('transitionPrevent', this) unless @prevented
      @prevented = true
      this
  
    abort: ->
      Router.notify('transitionAbort', this) unless @aborted
      @aborted = true
      this
  
    dispatch: ->
      Router.dispatcher.dispatch(this)
  
    retry: ->
      @dispatch()
  
    toString: ->
      s  = "transition"
      s += if @fromState then " #{@fromState.name}" else ' <initial>'
      s += " -> #{@toState.name}"
      s
  Router.once 'start', ->
    Router.on 'routeChange', (route) ->
      state = Router.stateMatcher.match(route)
      Router.transition(state, state.params(route), route)
  
  Router.on 'start', ->
    Router.history.start()
  
  Router.on 'stop', ->
    Router.history.stop()
  
  Router.once 'debug', ->
    Router.once 'routeChange', (route) ->
      console.debug "[#{Router}] Started with route '#{route}'"
  
      Router.on 'routeChange', (route) ->
        console.debug "[#{Router}] Route changed '#{route}'"
  
    Router.on 'fragmentUpdate', (fragment, replace) ->
      console.debug "[#{Router}] " + if replace
        "Replaced hash in history with '#{fragment}'"
      else "Set hash to history '#{fragment}'"
  
    Router.on 'pathUpdate', (path, replace) ->
      console.debug "[#{Router}] " + if replace
        "Replaced state in history with '#{path}'"
      else "Pushed state to history '#{path}'"
  
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
  
    @property 'path', ->
      @constructor.derivePath(@location)
  
    @property 'fragment', ->
      @constructor.deriveFragment(@location)
  
    @property 'route', ->
      if @pushStateBased then @path else @fragment
  
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
  
  Router.reURIScheme = /^(\w+):(?:\/\/)?/
  
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
  
      Router.$(document).on('click', 'a', @intercept)
      @started = true
      this
  
    stop: ->
      unless @started
        throw new Error "[#{Router}] Links interceptor hasn't been started!"
  
      Router.$(document).off('click', 'a', @intercept)
      @started = false
      this
  
    intercept: (e) ->
      # Only intercept left-clicks
      return if e.which isnt 1
  
      $link = Router.$(e.currentTarget)
  
      # Get the href
      # Stop processing if there isn't one
      return unless href = $link.attr('href')
  
      # Determine if we're supposed to bypass the link
      # based on its attributes
      intercept = $link.attr('intercept') ? $link.data('intercept')
      return if intercept is 'false'
  
      # Return if the URI is absolute, or if URI contains scheme
      return if Router.matchURIScheme(href)?
  
      # If we haven't been stopped yet, then we prevent the default action
      e.preventDefault()
  
      route = if Router.history.pushStateBased
        History.derivePath($link[0])
      else
        History.deriveFragment($link[0])
  
      Router.navigate(route, true)
      return
  
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