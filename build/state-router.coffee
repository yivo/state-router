((root, factory) ->
  if typeof define is 'function' and define.amd
    define ['lodash', 'jquery', 'XRegExp', 'strict-parameters', 'pub-sub', 'yess', 'coffee-concerns'], (_, $, XRegExpAPI, StrictParameters, PublisherSubscriber) ->
      root.StateRouter = factory(root, _, $, XRegExpAPI, StrictParameters, PublisherSubscriber)
  else if typeof module is 'object' && typeof module.exports is 'object'
    module.exports = factory(root, require('lodash'), require('jquery'), require('XRegExp'), require('strict-parameters'), require('pub-sub'), require('yess'), require('coffee-concerns'))
  else
    root.StateRouter = factory(root, root._, root.$, root.XRegExp, root.StrictParameters, root.PublisherSubscriber)
  return
)(this, (root, _, $, XRegExpAPI, StrictParameters, PublisherSubscriber) ->
  XRegExp = XRegExpAPI.XRegExp or XRegExpAPI
  
  StateDefaultsAccess =
  
    getDefaultParam: (param) ->
      state = this
      while state
        value = state.getOwnDefaultParam(param)
        return value if value?
        state = state.base
  
    getOwnDefaultParam: (param) ->
      ownDefaults = @getOwnDefaultParams()
      ownDefaults?[param]
  
    getOwnDefaultParams: ->
      @_defaultParams
  
    hasOwnDefaultParam: (param) ->
      @getOwnDefaultParam(param)?
  StateParametersExtract =
  
    extractParams: (route) ->
      helper = Router.loadParamHelper()
      match  = @pattern.match(route)
      params = __version: helper.hashCode(route)
  
      for own param, value of match when not helper.refersToRegexMatch(param)
        params[param] = if value?
          unless helper.refersToQueryString(param)
            helper.decode(param, value)
          else value
        else
          @getDefaultParam(param)
      params
  
    # TODO Refactor name
    extractBeginningParams: (route) ->
      helper = Router.loadParamHelper()
      match  = @pattern.matchBeginning(route)
      params =
        __version: if match? then helper.hashCode(match[0])
        query: @extractQueryString(route)
  
      for own param, value of match when not helper.refersToRegexMatch(param)
        params[param] = if value?
          helper.decode(param, value)
        else
          @getOwnDefaultParam(param)
      params
  
    extractQueryString: (route) ->
      XRegExp.exec(route, Router.loadPatternCompiler().reQueryString)?.query
  StateRouteAssemble = do ->
  
    {extend} = _
  
    paramAssembler: (match, optional, token, splat, param) ->
      value = if @_assembleParams?[param]?
        @_assembleParams[param]
      else
        @getDefaultParam(param)
  
      if not value?
        if not optional
          throw "#{param} is required"
        ''
      else
        (token || '') + if splat
          encodeURI(value)
        else encodeURIComponent(value)
  
    hasCustomRouteAssembler: ->
      !!@_customAssembler
  
    getCustomRouteAssembler: ->
      @_customAssembler
  
    requiresCustomRouteAssembler: ->
      @pattern.isRegexBased()
  
    assembleRoute: (params) ->
      route = if @base
        @base.assembleRoute(params)
      else ''
  
      own = @assembleOwnRoute(params)
      route = if route
        route + (if own then '/' else '') + own
      else own
  
      if params?.query?
        route = route + (if params.query[0] is '?'
          ''
        else '?') + params.query
      route
  
    assembleOwnRoute: (params) ->
      if @hasCustomRouteAssembler()
        assembler = @getCustomRouteAssembler()
        own = assembler.call(this, extend({}, @getOwnDefaultParams(), params), this)
  
      else if @requiresCustomRouteAssembler()
        throw "To assemble route from pattern which
          is based on regex you need to define custom assembler.
          In state '#{@getName()}'"
  
      else
        @_assembleParams = params
        path             = @pattern.getOwnPath()
        pathDecorator    = Router.pathDecorator
        own              = pathDecorator.replaceParams(path, @paramAssembler)
        @_assembleParams = null
      own
  # TODO Configurable reload on query change
  class Router
  
    {last, isString, extend} = _
  
    extend(this, PublisherSubscriber.InstanceMembers or PublisherSubscriber)
  
    @$: $
  
    @controller = (name, klass) ->
      Router.loadControllerStore().registerClass(name, klass)
  
    @state = do ->
      parentsStack = []
  
      (name, options, children) ->
        base  = last(parentsStack)
        state = Router.loadStateBuilder().build(name, base, options)
        Router.loadStateStore().push(state)
  
        if children
          parentsStack.push(state)
          children()
          parentsStack.pop()
        Router
  
    @map = (callback) ->
      callback.call(this, Router.state)
  
    @urlTo = (stateName, params) ->
      unless state = Router.loadStateStore().get(stateName)
        throw new Error("State '#{stateName}' wasn't found")
  
      (if Router.history.hashChangeBased
        '#'
      else '/') + state.assembleRoute(params)
  
    @start: ->
      Router.loadHistory().start()
      Router.loadLinksInterceptor().start()
  Router.createState = (options) ->
    new State(options)
  
  class State
  
    @include PublisherSubscriber
    @include StrictParameters
    @include StateDefaultsAccess
    @include StateParametersExtract
    @include StateRouteAssemble
  
    @param 'name',       as: '_name', required: yes
    @param 'pattern',    required: yes
    @param 'base'
    @param 'assembler',  as: '_customAssembler'
    @param 'controller', as: '_controller'
    @param 'defaults',   as: '_defaultParams'
    @param '404',        as: '_404'
    @param 'abstract',   as: '_abstract'
  
    {bindMethod, isFunction, extend} = _
  
    constructor: (options) ->
      @mergeParams(options)
      bindMethod(this, 'paramAssembler')
      if @isAbstract() and @is404()
        throw new Error('State can be either abstract or 404 or none')
  
    getName: ->
      @_name
  
    hasComputedControllerName: ->
      isFunction(@_controller)
  
    getControllerName: ->
      unless @hasComputedControllerName()
        @_controller
  
    computeControllerName: ->
      if @hasComputedControllerName()
        @_controller.apply(this, arguments)
  
    isAbstract: ->
      !!@_abstract
  
    is404: ->
      !!@_404
  
    isRoot: ->
      !@base
  
    getRoot: ->
      state = this
  
      loop
        break if not state.base
        state = state.base
  
      if state isnt this
        state
  
    getChain: ->
      chain = [this]
      state = this
      while state = state.base
        chain.unshift(state)
      chain
  Router.loadStateStore = ->
    @stateStore ||= new StateStore(@stateStoreOptions)
  
  class StateStore
  
    @include StrictParameters
  
    length: 0
  
    arrayPush = Array::push
  
    constructor: (options) ->
      @mergeParams(options)
      @_byName = {}
  
    push: (state) ->
      arrayPush.call(this, state)
      @_byName[state.getName()] = state
      this
  
    get: (name) ->
      @_byName[name]
  
    findOne: (predicate, context) ->
      for state in this when predicate.call(context, state)
        return state
  Router.loadStateBuilder = ->
    @stateBuilder ||= new StateBuilder(@stateBuilderOptions)
  
  class StateBuilder
  
    @include StrictParameters
  
    {extend} = _
  
    constructor: (options) ->
      @mergeParams(options)
  
    build: (name, base, data) ->
      if base
        name = base.getName() + '.' + name
        basePattern = base.pattern
  
      pattern = if data.path?
        Pattern.fromPath(data.path, base: basePattern)
  
      else if data.pattern?
        Pattern.fromRegex(data.pattern, base: basePattern)
  
      else if data['404']
        Pattern.fromRegex('.*', base: basePattern)
  
      else
        throw new Error("Neither path nor pattern specified for state: '#{name}'")
  
      extend data, {name, base, pattern}
  
      Router.createState(data)
  Router.loadStateMatcher = ->
    @stateMatcher ||= new StateMatcher(@stateMatcherOptions)
  
  class StateMatcher
  
    @include StrictParameters
  
    constructor: (options) ->
      @mergeParams(options)
  
    match: (route, options) ->
      store = Router.loadStateStore()
  
      match = store.findOne (state) ->
        !state.isAbstract() and !state.is404() and state.pattern.test(route)
  
      match ||= store.findOne (state) ->
        state.is404()
  
      unless match
        throw new Error("None of states matched route '#{route}' and no 404 state was found")
  
      match
  class Pattern
  
    @include StrictParameters
  
    @param 'source', as: '_source', required: yes
    @param 'path',   as: '_ownPath'
    @param 'base'
  
    constructor: (data) ->
      @mergeParams(data)
  
      if baseSource = @base?.getSource()
        @_source = baseSource + if @_source
          '/' + @_source
        else ''
  
      @_type   = @deriveType()
      compiler = Router.loadPatternCompiler()
      @reRoute = compiler.compile(@_source, starts: yes, ends: yes)
      @reRouteBeginning = compiler.compile(@_source, starts: yes, ends: no)
  
    deriveType: ->
      if @_ownPath? then 'path' else 'regex'
  
    test: (route) ->
      @reRoute.test(route)
  
    testBeginning: (route) ->
      @reRouteBeginning.test(route)
  
    match: (route) ->
      XRegExp.exec(route, @reRoute)
  
    matchBeginning: (route) ->
      XRegExp.exec(route, @reRouteBeginning)
  
    isRegexBased: ->
      @_type is 'regex'
  
    isPathBased: ->
      @_type is 'path'
  
    getSource: ->
      @_source
  
    getOwnPath: ->
      @_ownPath
  
    @fromPath: (path, options) ->
      decorator = Router.loadPathDecorator()
      source    = decorator.preprocessParams(decorator.escape(path))
      (options ||= {}).path = path
      @fromRegex(source, options)
  
    @fromRegex: (source, options) ->
      (options ||= {}).source = source
      new this(options)
  Router.loadPatternCompiler = ->
    @patternCompiler ||= new PatternCompiler(@pattermCompilerOptions)
  
  class PatternCompiler
  
    @include StrictParameters
  
    rsQueryString: '(?:\\?(?<query>([\\s\\S]*)))?'
    reQueryString: XRegExp(@::rsQueryString + '$')
    leftBoundary: '^'
    rightBoundary: @::rsQueryString + '$'
  
    {isEnabled} = _
  
    constructor: (options) ->
      @mergeParams(options)
  
    compile: (source, options) ->
      XRegExp(@bound(source, options))
  
    bound: (source, options) ->
      starts = isEnabled(options, 'starts')
      ends   = isEnabled(options, 'ends')
      empty  = source is ''
  
      if starts
        source = @leftBoundary + source
  
        if empty and !ends
          source = source + @rsQueryString
  
      if ends
        source = source + @rightBoundary
  
      source
  Router.loadPathDecorator = ->
    @pathDecorator ||= new PathDecorator(@pathDecoratorOptions)
  
  class PathDecorator
  
    @include StrictParameters
  
    constructor: (options) ->
      @mergeParams(options)
  
    reEscape: /[\-{}\[\]+?.,\\\^$|#\s]/g
  
    escapeReplacement: '\\$&'
  
    reParam: /(\()?(.)?(\*)?:(\w+)\)?/g
  
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
  
  
  Router.loadDispatcher = ->
    @dispatcher ||= new Dispatcher(@dispatcherOptions)
  
  class Dispatcher
  
    @include StrictParameters
  
    {beforeConstructor, extend} = _
  
    constructor: (options) ->
      @mergeParams(options)
  
    dispatch: (transition, options) ->
      Router.notify('transitionBegin', transition, options)
  
      if transition.isPrevented()
        return false
  
      nextState           = transition.toState
      currentState        = transition.fromState
      nextStateChain      = nextState?.getChain() or []
      currentStateChain   = currentState?.getChain() or []
      enterStates         = []
      leaveStates         = []
      ignoreStates        = []
  
      try
        for state in currentStateChain
          if state in nextStateChain
            if not @needToReloadState(state, transition)
              ignoreStates.push(state)
            else
              leaveStates.unshift(state)
              enterStates.push(state)
          else
            leaveStates.unshift(state)
  
        for state in nextStateChain
          if (state not in enterStates) and (state not in ignoreStates)
            enterStates.push(state)
  
        for state in leaveStates
          @leaveState(state, transition)
  
        for state in enterStates
          @enterState(state, transition)
      catch error
        Router.notify('transitionError', transition, extend({}, options, {error}))
        return false
  
      Router.notify('transitionEnd', transition, options)
      true
  
    enterState: (state, transition) ->
      @_storeParams(state, state.extractBeginningParams(transition.route))
  
      ctrlStore = Router.loadControllerStore()
      ctrlName  = @_deriveControllerName(state, transition.toParams, transition)
      ctrlClass = ctrlName and ctrlStore.getClass(ctrlName)
  
      if ctrlClass
        rootState      = state.getRoot()
        rootCtrl       = rootState and @_getCtrl(rootState)
        parentCtrl     = state.base and @_getCtrl(state.base)
  
        ctrlClass      = beforeConstructor ctrlClass, ->
          @rootController   = rootCtrl or undefined
          @parentController = parentCtrl or undefined
  
        ctrl           = new ctrlClass(transition.toParams, transition)
  
        @_storeCtrl(state, ctrl)
        ctrl.enter?(transition.toParams, transition)
  
      state.notify('enter', state, transition)
      return
  
    leaveState: (state, transition) ->
      ctrl = @_getCtrl(state)
      @_removeParams(state)
      @_removeCtrl(state)
  
      ctrl?.leave?()
      state.notify('leave', state, transition)
      return
  
    needToReloadState: (state, transition) ->
      lastParams = @_getParams(state)
      nextParams = state.extractBeginningParams(transition.route)
      lastParams?.__version isnt nextParams?.__version
  
    _storeParams: (state, params) ->
      state._lastParams = params
  
    _storeCtrl: (state, ctrl) ->
      state._lastCtrl = ctrl
  
    _removeParams: (state) ->
      state._lastParams = undefined
  
    _removeCtrl: (state) ->
      state._lastCtrl = undefined
  
    _getParams: (state) ->
      state._lastParams
  
    _getCtrl: (state) ->
      state._lastCtrl
  
    _deriveControllerName: (state, params, transition) ->
      if state.hasComputedControllerName()
        state.computeControllerName(params, transition)
      else
        state.getControllerName()
  Router.loadParamHelper = ->
    @paramHelper ||= new ParamHelper(@paramHelperOptions)
  
  class ParamHelper
  
    @include StrictParameters
  
    reArrayIndex: /^[0-9]+$/
  
    constructor: (options) ->
      @mergeParams(options)
  
    refersToRegexMatch: (param) ->
      @reArrayIndex.test(param) or param in ['index', 'input']
  
    refersToQueryString: (param) ->
      param is 'query'
  
    decode: (param, value) ->
      decodeURIComponent(value)
  
    hashCode: (string) ->
      hash = 0
      for i in [0...string.length]
        char = string.charCodeAt(i)
        hash = ((hash << 5) - hash) + char
        hash = hash & hash # Convert to 32bit integer
      hash
  Router.loadControllerStore = ->
    @controllerStore ||= new ControllerStore(@controllerStoreOptions)
  
  class ControllerStore
  
    @include StrictParameters
  
    constructor: (options) ->
      @mergeParams(options)
      @_classByName = {}
  
    getClass: (name) ->
      @_classByName[name]
  
    registerClass: (name, klass) ->
      @_classByName[name] = klass
  Router.createTransition = (options) ->
    new Transition(options)
  
  # TODO Retry transition
  class Transition
  
    @include StrictParameters
  
    @param 'fromState'
    @param 'toState',  required: yes
    @param 'fromParams'
    @param 'toParams', alias: 'params'
    @param 'route',    required: yes
  
    constructor: (options) ->
      @mergeParams(options)
  
    prevent: ->
      @_prevented = yes
  
    isPrevented: ->
      !!@_prevented
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
        @load {@route}
  
    check: (e) ->
      route = @getRoute()
      if route isnt @route
        @load {route}
  
    load: ({route}) ->
      fixed = @_removeRouteAmbiguity(route)
  
      if route isnt fixed
        return @navigate(fixed, replace: yes, load: yes)
  
      @route     = route
      fromState  = Router.currentState
      fromParams = Router.previousTransition?.toParams
      toState    = Router.loadStateMatcher().match(route)
      toParams   = toState?.extractParams(route) or {}
      transition = Router.createTransition {fromState, fromParams, toState, toParams, route}
      result     = Router.loadDispatcher().dispatch(transition)
  
      if result
        Router.previousState      = Router.currentState
        Router.previousTransition = Router.currentTransition
        Router.currentState       = toState
        Router.currentTransition  = transition
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
          @_updatePath(route, options.replace)
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
  
    _updatePath: (route, replace) ->
      method = if replace then 'replaceState' else 'pushState'
      @history[method]({}, @document.title, '/' + route)
  
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
  Router.loadLinksInterceptor = ->
    @linksInterceptor ||= new LinksInterceptor(@linksInterceptorOptions)
  
  class LinksInterceptor
  
    @include StrictParameters
  
    reUriAnchor: /^#/
    reUriScheme: /^(\w+):(?:\/\/)?/
  
    {bindMethod} = _
  
    constructor: (options) ->
      @mergeParams(options)
      bindMethod(this, 'intercept')
  
    start: ->
      Router.$(document).on('click', 'a', @intercept)
  
    intercept: (e) ->
      # Only intercept left-clicks
      return if e.which isnt 1
  
      $link = Router.$(e.currentTarget)
  
      # Get the href; stop processing if there isn't one
      return unless href = $link.attr('href')
  
      # Determine if we're supposed to bypass the link
      # based on its attributes
  
      intercept = $link.attr('intercept') ? $link.data('intercept')
      return if intercept is 'false'
  
      # Return if the URL is absolute, or if the protocol is mailto or javascript
      return if @reUriAnchor.test(href) or @reUriScheme.test(href)
  
      # If we haven't been stopped yet, then we prevent the default action
      e.preventDefault()
  
      # Get the computed pathname of the link, removing
      # the leading slash. Regex required for IE8 support
      pathname = $link[0].pathname.replace(/^\//, '')
  
      Router.loadHistory().navigate(pathname, true)
  
  _.extend Router, {
    State
    StateStore
    StateBuilder
    StateDefaultsAccess
    StateParametersExtract
    StateRouteAssemble
    Dispatcher
    ControllerStore
    History
    PathDecorator
    PatternCompiler
    StateMatcher
    Transition
    Pattern
    ParamHelper
  }
)