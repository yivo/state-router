XRegExp = XRegExpAPI.XRegExp or XRegExpAPI

Router = {}

do ->
  names = 'history linksInterceptor paramHelper
    pathDecorator patternCompiler stateBuilder
    dispatcher stateMatcher stateStore'

  define = (name) ->
    keyName   = "_#{name}"
    loadName  = "load#{name.capitalize()}"
    className = name.classCase()

    Router[loadName] = ->
      Router[keyName] ||= new Router[className](_.result(Router, "#{name}Options"))

    PropertyAccessors.property(Router, name, readonly: yes, get: loadName)

  define(name) for name in names.split(/\s+/)

  PropertyAccessors.property(Router, 'states', readonly: yes, get: 'loadStateStore')
  return

# @include concerns/state-default-parameters.coffee
# @include concerns/state-route-parameters.coffee
# @include concerns/state-route-assemble.coffee
# @include concerns/state-store-framework-features.coffee
# @include state-router.coffee
# @include base-class.coffee
# @include state.coffee
# @include state-store.coffee
# @include state-builder.coffee
# @include state-matcher.coffee
# @include pattern.coffee
# @include pattern-compiler.coffee
# @include path-decorator.coffee
# @include dispatcher.coffee
# @include param-helper.coffee
# @include transition.coffee
# @include history.coffee
# @include links-interceptor.coffee
# @include events.coffee

_.extend Router, {
  State
  StateStore
  StateBuilder
  StateDefaultParameters
  StateRouteParameters
  StateRouteAssemble
  StateStoreFrameworkFeatures
  Dispatcher
  History
  PathDecorator
  PatternCompiler
  StateMatcher
  Transition
  Pattern
  ParamHelper
  LinksInterceptor
}

Router
