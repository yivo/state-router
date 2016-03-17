XRegExp = XRegExpExports.XRegExp or XRegExpExports

Router = VERSION: '1.0.2'

do ->
  Router.property = PropertyAccessors.ClassMembers.property
  property        = (name, getter) -> Router.property(name, memo: yes, readonly: yes, silent: yes, getter)

  property 'history',          -> new @History(_.result(this, 'historyOptions'))
  property 'linksInterceptor', -> new @LinksInterceptor(_.result(this, 'linksInterceptorOptions'))
  property 'paramHelper',      -> new @ParamHelper(_.result(this, 'paramHelperOptions'))
  property 'pathDecorator',    -> new @PathDecorator(_.result(this, 'pathDecoratorOptions'))
  property 'patternCompiler',  -> new @PatternCompiler(_.result(this, 'patternCompilerOptions'))
  property 'stateBuilder',     -> new @StateBuilder(_.result(this, 'stateBuilderOptions'))
  property 'dispatcher',       -> new @Dispatcher(_.result(this, 'dispatcherOptions'))
  property 'stateMatcher',     -> new @StateMatcher(_.result(this, 'stateMatcherOptions'))
  property 'stateStore',       -> new @StateStore(_.result(this, 'stateStoreOptions'))
  property 'states',           -> @stateStore

# @include concerns/state-default-parameters.coffee
# @include concerns/state-route-parameters.coffee
# @include concerns/state-route-assemble.coffee
# @include concerns/state-store-framework-features.coffee
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
