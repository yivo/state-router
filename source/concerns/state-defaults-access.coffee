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