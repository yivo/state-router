StateStoreFrameworkFeatures = do ->

  {removeAt, insertAt} = _

  Concern = {}

  for key, value of {Before: 0, After: 1}
    Concern['insert' + key] = do (type = key.toLowerCase(), offset = value) ->
      (state, insertedState) ->
        _state    = @get(state)
        _newState = @get(insertedState)
        i         = @indexOf(_state)
        j         = @indexOf(_newState)

        if i < 0
          throw new Error "Can't insert #{type} state because it does not present in store"

        removeAt(this, j) if j > -1
        insertAt(this, i + offset, _newState)
        this

  Concern