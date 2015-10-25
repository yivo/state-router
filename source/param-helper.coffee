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
