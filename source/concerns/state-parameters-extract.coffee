StateParametersExtract =

  extractParams: (route) ->
    helper = Router.paramHelper
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
    helper = Router.paramHelper
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
    XRegExp.exec(route, Router.patternCompiler.reQueryString)?.query