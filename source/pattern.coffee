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