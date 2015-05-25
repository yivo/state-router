# TODO Configurable reload on query change
class Router

  {last, isString, extend} = _

  extend(this, PublisherSubscriber.InstanceMembers or PublisherSubscriber)

  @$: $

  @controller = (name, klass) ->
    Router.loadControllerStore().registerClass(name, klass)

  @state = do ->
    parentsStack = []

    (name, options, children) ->
      base  = last(parentsStack)
      state = Router.loadStateBuilder().build(name, base, options)
      Router.loadStateStore().push(state)

      if children
        parentsStack.push(state)
        children()
        parentsStack.pop()
      Router

  @map = (callback) ->
    callback.call(this, Router.state)

  @urlTo = (stateName, params) ->
    unless state = Router.loadStateStore().get(stateName)
      throw new Error("State '#{stateName}' wasn't found")

    (if Router.history.hashChangeBased
      '#'
    else '/') + state.assembleRoute(params)

  @start: ->
    Router.loadHistory().start()
    Router.loadLinksInterceptor().start()