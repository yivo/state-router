XRegExp = XRegExpAPI.XRegExp or XRegExpAPI

# @include concerns/state-default-parameters.coffee
# @include concerns/state-route-parameters.coffee
# @include concerns/state-route-assemble.coffee
# @include base-class.coffee
# @include state-router.coffee
# @include state.coffee
# @include state-store.coffee
# @include state-builder.coffee
# @include state-matcher.coffee
# @include pattern.coffee
# @include pattern-compiler.coffee
# @include path-decorator.coffee
# @include dispatcher.coffee
# @include param-helper.coffee
# @include controller-store.coffee
# @include transition.coffee
# @include history.coffee
# @include links-interceptor.coffee

do ->
  names = [
    'history', 'linksInterceptor', 'paramHelper',
    'pathDecorator', 'patternCompiler', 'stateBuilder',
    'controllerStore', 'dispatcher', 'stateMatcher', 'stateStore'
  ]

  define = (name) ->
    eval "var Class = #{name.classCase()}"
    Router["load#{name.capitalize()}"] = ->
      this["_#{name}"] ||= new Class(_.result(this, "#{name}Options"))
    PropertyAccessors.property(Router, name, readonly: yes, get: "load#{name.capitalize()}")

  define(name) for name in names
  return

_.extend Router, {
  State
  StateStore
  StateBuilder
  StateDefaultParameters
  StateRouteParameters
  StateRouteAssemble
  Dispatcher
  ControllerStore
  History
  PathDecorator
  PatternCompiler
  StateMatcher
  Transition
  Pattern
  ParamHelper
}