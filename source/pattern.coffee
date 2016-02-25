class Pattern extends CoreObject

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
