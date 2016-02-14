class BaseClass

  @include Callbacks
  @include PropertyAccessors
  @include PublisherSubscriber
  @include ConstructWith

  constructor: (options) ->
    @bindCallbacks()
    @runInitializers(options)
