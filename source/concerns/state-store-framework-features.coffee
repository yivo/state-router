StateStoreFrameworkFeatures = do ->

  Concern = {}

  for key, value of {Before: 0, After: 1}
    Concern['insert' + key] = do (type = key.toLowerCase(), offset = value) ->
      (state, insertedState) ->
        _state    = @get(state)
        _newState = @get(insertedState)
        i         = @indexOf(_state)
        j         = @indexOf(_newState)

        if i < 0
          throw new Error "[#{Router}] Can't insert #{_newState} #{type} #{_state}
            because #{_state} does not exist in store"

        _.removeAt(this, j) if j > -1
        _.insertAt(this, i + offset, _newState)
        this

  Concern