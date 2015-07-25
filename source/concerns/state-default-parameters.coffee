StateDefaultParameters =

  included: (Class) ->
    Class.param 'defaults', as: '_ownDefaults'

    Class.property 'ownDefaults', ->
      if _.isFunction(@_ownDefaults)
        @_ownDefaults = @_ownDefaults()

      unless _.isObject(@_ownDefaults)
        @_ownDefaults = {}

      @_ownDefaults

    Class.property 'defaults', ->
      state = this
      params = {}
      while state
        defaults = state.ownDefaults
        if defaults
          for param, value of defaults
            params[param] ?= value
        state = state.base
      params