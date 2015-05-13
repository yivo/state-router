Router.loadControllerStore = ->
  @controllerStore ||= new ControllerStore(@controllerStoreOptions)

class ControllerStore

  @include StrictParameters

  constructor: (options) ->
    @mergeParams(options)
    @_classByName = {}
    @_instanceByName = {}

  getClass: (name) ->
    @_classByName[name]

  getInstance: (name) ->
    @_instanceByName[name]

  registerClass: (name, klass) ->
    @_classByName[name] = klass

  registerInstance: (name, instance) ->
    @_instanceByName[name] = instance

  getInstance: (name) ->
    @_instanceByName[name]

  popInstance: (name) ->
    instance = @getInstance(name)
    @_instanceByName[name] = null
    instance