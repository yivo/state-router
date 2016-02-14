StateDefaultParameters =

  included: (Class) ->
    Class.property 'ownDefaults', readonly: true, ->
      @options.defaults?() or @options.defaults or {}

    Class.property 'defaults', readonly: true, ->
      state  = this
      params = {}
      while state
        defaults = state.ownDefaults
        if defaults
          for param, value of defaults
            params[param] ?= value
        state = state.base
      params
