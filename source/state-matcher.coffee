Router.loadStateMatcher = ->
  @stateMatcher ||= new StateMatcher(@stateMatcherOptions)

class StateMatcher

  @include StrictParameters

  constructor: (options) ->
    @mergeParams(options)

  match: (route, options) ->
    store = Router.loadStateStore()

    match = store.findOne (state) ->
      !state.isAbstract() and !state.is404() and state.pattern.test(route)

    match ||= store.findOne (state) ->
      state.is404()

    unless match
      throw new Error("None of states matched route '#{route}' and no 404 state was found")

    match