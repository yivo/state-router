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