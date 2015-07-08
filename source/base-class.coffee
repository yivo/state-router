class BaseClass

  @include StrictParameters
  @include PublisherSubscriber

  constructor: (options) ->
    @mergeParams(options)