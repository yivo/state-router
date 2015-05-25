XRegExp = XRegExpAPI.XRegExp or XRegExpAPI

# @include concerns/state-defaults-access.coffee
# @include concerns/state-parameters-extract.coffee
# @include concerns/state-route-assemble.coffee
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

_.extend Router, {
  State
  StateStore
  StateBuilder
  StateDefaultsAccess
  StateParametersExtract
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