class StateMatcher extends BaseClass

  match: (route) ->
    store = Router.loadStateStore()

    match = store.findOne (state) ->
      !state.isAbstract and !state.is404 and state.pattern.test(route)

    match ||= store.findOne (state) ->
      state.is404

    unless match
      # TODO Error message
      throw new Error("None of states matched route '#{route}' and no 404 state was found")

    match