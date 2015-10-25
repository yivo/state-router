class StateMatcher extends BaseClass

  match: (route) ->
    states = Router.states

    match = states.findOne (state) ->
      !state.abstract and !state.handles404 and state.pattern.test(route)

    match ||= states.findOne (state) ->
      state.handles404

    unless match
      throw new Error "[#{Router}] None of states matched route '#{route}' and no 404 state was found"

    match
