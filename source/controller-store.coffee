Router.loadControllerStore = ->
  @controllerStore ||= new ControllerStore(@controllerStoreOptions)

class ControllerStore

  @include StrictParameters

  constructor: (options) ->
    @mergeParams(options)
    @_classByName = {}

  getClass: (name) ->
    @_classByName[name]

  registerClass: (name, klass) ->
    @_classByName[name] = klass