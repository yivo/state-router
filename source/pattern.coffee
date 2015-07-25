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