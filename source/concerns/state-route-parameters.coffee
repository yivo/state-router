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
