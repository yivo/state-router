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