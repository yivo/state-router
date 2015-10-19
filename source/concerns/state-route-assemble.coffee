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