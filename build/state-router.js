(function() {
  var hasProp = {}.hasOwnProperty,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  (function(root, factory) {
    if (typeof define === 'function' && define.amd) {
      define(['lodash', 'jquery', 'XRegExp', 'strict-parameters', 'pub-sub', 'yess', 'coffee-concerns'], function(_, $, XRegExpAPI, StrictParameters, PublisherSubscriber) {
        return root.StateRouter = factory(root, _, $, XRegExpAPI, StrictParameters, PublisherSubscriber);
      });
    } else if (typeof module === 'object' && typeof module.exports === 'object') {
      module.exports = factory(root, require('lodash'), require('jquery'), require('XRegExp'), require('strict-parameters'), require('pub-sub'), require('yess'), require('coffee-concerns'));
    } else {
      root.StateRouter = factory(root, root._, root.$, root.XRegExp, root.StrictParameters, root.PublisherSubscriber);
    }
  })(this, function(root, _, $, XRegExpAPI, StrictParameters, PublisherSubscriber) {
    var ControllerStore, Dispatcher, History, LinksInterceptor, ParamHelper, PathDecorator, Pattern, PatternCompiler, Router, State, StateBuilder, StateDefaultsAccess, StateMatcher, StateParametersExtract, StateRouteAssemble, StateStore, Transition, XRegExp;
    XRegExp = XRegExpAPI.XRegExp || XRegExpAPI;
    StateDefaultsAccess = {
      getDefaultParam: function(param) {
        var state, value;
        state = this;
        while (state) {
          value = state.getOwnDefaultParam(param);
          if (value != null) {
            return value;
          }
          state = state.base;
        }
      },
      getOwnDefaultParam: function(param) {
        var ownDefaults;
        ownDefaults = this.getOwnDefaultParams();
        return ownDefaults != null ? ownDefaults[param] : void 0;
      },
      getOwnDefaultParams: function() {
        return this._defaultParams;
      },
      hasOwnDefaultParam: function(param) {
        return this.getOwnDefaultParam(param) != null;
      }
    };
    StateParametersExtract = {
      extractParams: function(route) {
        var helper, match, param, params, value;
        helper = Router.loadParamHelper();
        match = this.pattern.match(route);
        params = {
          __version: helper.hashCode(route)
        };
        for (param in match) {
          if (!hasProp.call(match, param)) continue;
          value = match[param];
          if (!helper.refersToRegexMatch(param)) {
            params[param] = value != null ? !helper.refersToQueryString(param) ? helper.decode(param, value) : value : this.getDefaultParam(param);
          }
        }
        return params;
      },
      extractBeginningParams: function(route) {
        var helper, match, param, params, value;
        helper = Router.loadParamHelper();
        match = this.pattern.matchBeginning(route);
        params = {
          __version: match != null ? helper.hashCode(match[0]) : void 0,
          query: this.extractQueryString(route)
        };
        for (param in match) {
          if (!hasProp.call(match, param)) continue;
          value = match[param];
          if (!helper.refersToRegexMatch(param)) {
            params[param] = value != null ? helper.decode(param, value) : this.getOwnDefaultParam(param);
          }
        }
        return params;
      },
      extractQueryString: function(route) {
        var ref;
        return (ref = XRegExp.exec(route, Router.loadPatternCompiler().reQueryString)) != null ? ref.query : void 0;
      }
    };
    StateRouteAssemble = (function() {
      var extend;
      extend = _.extend;
      return {
        paramAssembler: function(match, optional, token, splat, param) {
          var ref, value;
          value = ((ref = this._assembleParams) != null ? ref[param] : void 0) != null ? this._assembleParams[param] : this.getDefaultParam(param);
          if (value == null) {
            if (!optional) {
              throw param + " is required";
            }
            return '';
          } else {
            return (token || '') + (splat ? encodeURI(value) : encodeURIComponent(value));
          }
        },
        hasCustomRouteAssembler: function() {
          return !!this._customAssembler;
        },
        getCustomRouteAssembler: function() {
          return this._customAssembler;
        },
        requiresCustomRouteAssembler: function() {
          return this.pattern.isRegexBased();
        },
        assembleRoute: function(params) {
          var own, route;
          route = this.base ? this.base.assembleRoute(params) : '';
          own = this.assembleOwnRoute(params);
          route = route ? route + (own ? '/' : '') + own : own;
          if ((params != null ? params.query : void 0) != null) {
            route = route + (params.query[0] === '?' ? '' : '?') + params.query;
          }
          return route;
        },
        assembleOwnRoute: function(params) {
          var assembler, own, path, pathDecorator;
          if (this.hasCustomRouteAssembler()) {
            assembler = this.getCustomRouteAssembler();
            own = assembler.call(this, extend({}, this.getOwnDefaultParams(), params), this);
          } else if (this.requiresCustomRouteAssembler()) {
            throw "To assemble route from pattern which is based on regex you need to define custom assembler. In state '" + (this.getName()) + "'";
          } else {
            this._assembleParams = params;
            path = this.pattern.getOwnPath();
            pathDecorator = Router.pathDecorator;
            own = pathDecorator.replaceParams(path, this.paramAssembler);
            this._assembleParams = null;
          }
          return own;
        }
      };
    })();
    Router = (function() {
      var extend, isString, last;

      function Router() {}

      last = _.last, isString = _.isString, extend = _.extend;

      extend(Router, PublisherSubscriber.InstanceMembers || PublisherSubscriber);

      Router.$ = $;

      Router.controller = function(name, klass) {
        return Router.loadControllerStore().registerClass(name, klass);
      };

      Router.state = (function() {
        var parentsStack;
        parentsStack = [];
        return function(name, options, children) {
          var base, state;
          base = last(parentsStack);
          state = Router.loadStateBuilder().build(name, base, options);
          Router.loadStateStore().push(state);
          if (children) {
            parentsStack.push(state);
            children();
            parentsStack.pop();
          }
          return Router;
        };
      })();

      Router.map = function(callback) {
        return callback.call(this, Router.state);
      };

      Router.urlTo = function(stateName, params) {
        var state;
        if (!(state = Router.loadStateStore().get(stateName))) {
          throw new Error("State '" + stateName + "' wasn't found");
        }
        return (Router.history.hashChangeBased ? '#' : '/') + state.assembleRoute(params);
      };

      Router.start = function() {
        Router.loadHistory().start();
        return Router.loadLinksInterceptor().start();
      };

      return Router;

    })();
    Router.createState = function(options) {
      return new State(options);
    };
    State = (function() {
      var bindMethod, extend, isFunction;

      State.include(PublisherSubscriber);

      State.include(StrictParameters);

      State.include(StateDefaultsAccess);

      State.include(StateParametersExtract);

      State.include(StateRouteAssemble);

      State.param('name', {
        as: '_name',
        required: true
      });

      State.param('pattern', {
        required: true
      });

      State.param('base');

      State.param('assembler', {
        as: '_customAssembler'
      });

      State.param('controller', {
        as: '_controller'
      });

      State.param('defaults', {
        as: '_defaultParams'
      });

      State.param('404', {
        as: '_404'
      });

      State.param('abstract', {
        as: '_abstract'
      });

      bindMethod = _.bindMethod, isFunction = _.isFunction, extend = _.extend;

      function State(options) {
        this.mergeParams(options);
        bindMethod(this, 'paramAssembler');
        if (this.isAbstract() && this.is404()) {
          throw new Error('State can be either abstract or 404 or none');
        }
      }

      State.prototype.getName = function() {
        return this._name;
      };

      State.prototype.hasComputedControllerName = function() {
        return isFunction(this._controller);
      };

      State.prototype.getControllerName = function() {
        if (!this.hasComputedControllerName()) {
          return this._controller;
        }
      };

      State.prototype.computeControllerName = function() {
        if (this.hasComputedControllerName()) {
          return this._controller.apply(this, arguments);
        }
      };

      State.prototype.isAbstract = function() {
        return !!this._abstract;
      };

      State.prototype.is404 = function() {
        return !!this._404;
      };

      State.prototype.isRoot = function() {
        return !this.base;
      };

      State.prototype.getRoot = function() {
        var state;
        state = this;
        while (true) {
          if (!state.base) {
            break;
          }
          state = state.base;
        }
        if (state !== this) {
          return state;
        }
      };

      State.prototype.getChain = function() {
        var chain, state;
        chain = [this];
        state = this;
        while (state = state.base) {
          chain.unshift(state);
        }
        return chain;
      };

      return State;

    })();
    Router.loadStateStore = function() {
      return this.stateStore || (this.stateStore = new StateStore(this.stateStoreOptions));
    };
    StateStore = (function() {
      var arrayPush;

      StateStore.include(StrictParameters);

      StateStore.prototype.length = 0;

      arrayPush = Array.prototype.push;

      function StateStore(options) {
        this.mergeParams(options);
        this._byName = {};
      }

      StateStore.prototype.push = function(state) {
        arrayPush.call(this, state);
        this._byName[state.getName()] = state;
        return this;
      };

      StateStore.prototype.get = function(name) {
        return this._byName[name];
      };

      StateStore.prototype.findOne = function(predicate, context) {
        var j, len, state;
        for (j = 0, len = this.length; j < len; j++) {
          state = this[j];
          if (predicate.call(context, state)) {
            return state;
          }
        }
      };

      return StateStore;

    })();
    Router.loadStateBuilder = function() {
      return this.stateBuilder || (this.stateBuilder = new StateBuilder(this.stateBuilderOptions));
    };
    StateBuilder = (function() {
      var extend;

      StateBuilder.include(StrictParameters);

      extend = _.extend;

      function StateBuilder(options) {
        this.mergeParams(options);
      }

      StateBuilder.prototype.build = function(name, base, data) {
        var basePattern, pattern;
        if (base) {
          name = base.getName() + '.' + name;
          basePattern = base.pattern;
        }
        pattern = (function() {
          if (data.path != null) {
            return Pattern.fromPath(data.path, {
              base: basePattern
            });
          } else if (data.pattern != null) {
            return Pattern.fromRegex(data.pattern, {
              base: basePattern
            });
          } else if (data['404']) {
            return Pattern.fromRegex('.*', {
              base: basePattern
            });
          } else {
            throw new Error("Neither path nor pattern specified for state: '" + name + "'");
          }
        })();
        extend(data, {
          name: name,
          base: base,
          pattern: pattern
        });
        return Router.createState(data);
      };

      return StateBuilder;

    })();
    Router.loadStateMatcher = function() {
      return this.stateMatcher || (this.stateMatcher = new StateMatcher(this.stateMatcherOptions));
    };
    StateMatcher = (function() {
      StateMatcher.include(StrictParameters);

      function StateMatcher(options) {
        this.mergeParams(options);
      }

      StateMatcher.prototype.match = function(route, options) {
        var match, store;
        store = Router.loadStateStore();
        match = store.findOne(function(state) {
          return !state.isAbstract() && !state.is404() && state.pattern.test(route);
        });
        match || (match = store.findOne(function(state) {
          return state.is404();
        }));
        if (!match) {
          throw new Error("None of states matched route '" + route + "' and no 404 state was found");
        }
        return match;
      };

      return StateMatcher;

    })();
    Pattern = (function() {
      Pattern.include(StrictParameters);

      Pattern.param('source', {
        as: '_source',
        required: true
      });

      Pattern.param('path', {
        as: '_ownPath'
      });

      Pattern.param('base');

      function Pattern(data) {
        var baseSource, compiler, ref;
        this.mergeParams(data);
        if (baseSource = (ref = this.base) != null ? ref.getSource() : void 0) {
          this._source = baseSource + (this._source ? '/' + this._source : '');
        }
        this._type = this.deriveType();
        compiler = Router.loadPatternCompiler();
        this.reRoute = compiler.compile(this._source, {
          starts: true,
          ends: true
        });
        this.reRouteBeginning = compiler.compile(this._source, {
          starts: true,
          ends: false
        });
      }

      Pattern.prototype.deriveType = function() {
        if (this._ownPath != null) {
          return 'path';
        } else {
          return 'regex';
        }
      };

      Pattern.prototype.test = function(route) {
        return this.reRoute.test(route);
      };

      Pattern.prototype.testBeginning = function(route) {
        return this.reRouteBeginning.test(route);
      };

      Pattern.prototype.match = function(route) {
        return XRegExp.exec(route, this.reRoute);
      };

      Pattern.prototype.matchBeginning = function(route) {
        return XRegExp.exec(route, this.reRouteBeginning);
      };

      Pattern.prototype.isRegexBased = function() {
        return this._type === 'regex';
      };

      Pattern.prototype.isPathBased = function() {
        return this._type === 'path';
      };

      Pattern.prototype.getSource = function() {
        return this._source;
      };

      Pattern.prototype.getOwnPath = function() {
        return this._ownPath;
      };

      Pattern.fromPath = function(path, options) {
        var decorator, source;
        decorator = Router.loadPathDecorator();
        source = decorator.preprocessParams(decorator.escape(path));
        (options || (options = {})).path = path;
        return this.fromRegex(source, options);
      };

      Pattern.fromRegex = function(source, options) {
        (options || (options = {})).source = source;
        return new this(options);
      };

      return Pattern;

    })();
    Router.loadPatternCompiler = function() {
      return this.patternCompiler || (this.patternCompiler = new PatternCompiler(this.pattermCompilerOptions));
    };
    PatternCompiler = (function() {
      var isEnabled;

      PatternCompiler.include(StrictParameters);

      PatternCompiler.prototype.rsQueryString = '(?:\\?(?<query>([\\s\\S]*)))?';

      PatternCompiler.prototype.reQueryString = XRegExp(PatternCompiler.prototype.rsQueryString + '$');

      PatternCompiler.prototype.leftBoundary = '^';

      PatternCompiler.prototype.rightBoundary = PatternCompiler.prototype.rsQueryString + '$';

      isEnabled = _.isEnabled;

      function PatternCompiler(options) {
        this.mergeParams(options);
      }

      PatternCompiler.prototype.compile = function(source, options) {
        return XRegExp(this.bound(source, options));
      };

      PatternCompiler.prototype.bound = function(source, options) {
        var empty, ends, starts;
        starts = isEnabled(options, 'starts');
        ends = isEnabled(options, 'ends');
        empty = source === '';
        if (starts) {
          source = this.leftBoundary + source;
          if (empty && !ends) {
            source = source + this.rsQueryString;
          }
        }
        if (ends) {
          source = source + this.rightBoundary;
        }
        return source;
      };

      return PatternCompiler;

    })();
    Router.loadPathDecorator = function() {
      return this.pathDecorator || (this.pathDecorator = new PathDecorator(this.pathDecoratorOptions));
    };
    PathDecorator = (function() {
      PathDecorator.include(StrictParameters);

      function PathDecorator(options) {
        this.mergeParams(options);
      }

      PathDecorator.prototype.reEscape = /[\-{}\[\]+?.,\\\^$|#\s]/g;

      PathDecorator.prototype.escapeReplacement = '\\$&';

      PathDecorator.prototype.reParam = /(\()?(.)?(\*)?:(\w+)\)?/g;

      PathDecorator.prototype.paramPreprocessor = function(match, optional, token, splat, param) {
        var ret;
        ret = ("(?:" + (token || '') + "(?<" + param + ">") + (splat ? '[^?]*?' : '[^/?]+') + '))';
        if (optional) {
          return "(?:" + ret + ")?";
        } else {
          return ret;
        }
      };

      PathDecorator.prototype.preprocessParams = function(path) {
        return this.replaceParams(path, this.paramPreprocessor);
      };

      PathDecorator.prototype.replaceParams = function(path, replacement) {
        return path.replace(this.reParam, replacement);
      };

      PathDecorator.prototype.escape = function(path) {
        return path.replace(this.reEscape, this.escapeReplacement);
      };

      return PathDecorator;

    })();
    Router.loadDispatcher = function() {
      return this.dispatcher || (this.dispatcher = new Dispatcher(this.dispatcherOptions));
    };
    Dispatcher = (function() {
      var beforeConstructor, extend;

      Dispatcher.include(StrictParameters);

      beforeConstructor = _.beforeConstructor, extend = _.extend;

      function Dispatcher(options) {
        this.mergeParams(options);
      }

      Dispatcher.prototype.dispatch = function(transition, options) {
        var currentState, currentStateChain, enterStates, error, ignoreStates, j, k, l, leaveStates, len, len1, len2, len3, m, nextState, nextStateChain, state;
        Router.notify('transitionBegin', transition, options);
        if (transition.isPrevented()) {
          return false;
        }
        nextState = transition.toState;
        currentState = transition.fromState;
        nextStateChain = (nextState != null ? nextState.getChain() : void 0) || [];
        currentStateChain = (currentState != null ? currentState.getChain() : void 0) || [];
        enterStates = [];
        leaveStates = [];
        ignoreStates = [];
        try {
          for (j = 0, len = currentStateChain.length; j < len; j++) {
            state = currentStateChain[j];
            if (indexOf.call(nextStateChain, state) >= 0) {
              if (!this.needToReloadState(state, transition)) {
                ignoreStates.push(state);
              } else {
                leaveStates.unshift(state);
                enterStates.push(state);
              }
            } else {
              leaveStates.unshift(state);
            }
          }
          for (k = 0, len1 = nextStateChain.length; k < len1; k++) {
            state = nextStateChain[k];
            if ((indexOf.call(enterStates, state) < 0) && (indexOf.call(ignoreStates, state) < 0)) {
              enterStates.push(state);
            }
          }
          for (l = 0, len2 = leaveStates.length; l < len2; l++) {
            state = leaveStates[l];
            this.leaveState(state, transition);
          }
          for (m = 0, len3 = enterStates.length; m < len3; m++) {
            state = enterStates[m];
            this.enterState(state, transition);
          }
        } catch (_error) {
          error = _error;
          Router.notify('transitionError', transition, extend({}, options, {
            error: error
          }));
          return false;
        }
        Router.notify('transitionEnd', transition, options);
        return true;
      };

      Dispatcher.prototype.enterState = function(state, transition) {
        var ctrl, ctrlClass, ctrlName, ctrlStore, parentCtrl, rootCtrl, rootState;
        this._storeParams(state, state.extractBeginningParams(transition.route));
        ctrlStore = Router.loadControllerStore();
        ctrlName = this._deriveControllerName(state, transition.toParams, transition);
        ctrlClass = ctrlName && ctrlStore.getClass(ctrlName);
        if (ctrlClass) {
          rootState = state.getRoot();
          rootCtrl = rootState && this._getCtrl(rootState);
          parentCtrl = state.base && this._getCtrl(state.base);
          ctrlClass = beforeConstructor(ctrlClass, function() {
            this.rootController = rootCtrl || void 0;
            return this.parentController = parentCtrl || void 0;
          });
          ctrl = new ctrlClass(transition.toParams, transition);
          this._storeCtrl(state, ctrl);
          if (typeof ctrl.enter === "function") {
            ctrl.enter(transition.toParams, transition);
          }
        }
        state.notify('enter', state, transition);
      };

      Dispatcher.prototype.leaveState = function(state, transition) {
        var ctrl;
        ctrl = this._getCtrl(state);
        this._removeParams(state);
        this._removeCtrl(state);
        if (ctrl != null) {
          if (typeof ctrl.leave === "function") {
            ctrl.leave();
          }
        }
        state.notify('leave', state, transition);
      };

      Dispatcher.prototype.needToReloadState = function(state, transition) {
        var lastParams, nextParams;
        lastParams = this._getParams(state);
        nextParams = state.extractBeginningParams(transition.route);
        return (lastParams != null ? lastParams.__version : void 0) !== (nextParams != null ? nextParams.__version : void 0);
      };

      Dispatcher.prototype._storeParams = function(state, params) {
        return state._lastParams = params;
      };

      Dispatcher.prototype._storeCtrl = function(state, ctrl) {
        return state._lastCtrl = ctrl;
      };

      Dispatcher.prototype._removeParams = function(state) {
        return state._lastParams = void 0;
      };

      Dispatcher.prototype._removeCtrl = function(state) {
        return state._lastCtrl = void 0;
      };

      Dispatcher.prototype._getParams = function(state) {
        return state._lastParams;
      };

      Dispatcher.prototype._getCtrl = function(state) {
        return state._lastCtrl;
      };

      Dispatcher.prototype._deriveControllerName = function(state, params, transition) {
        if (state.hasComputedControllerName()) {
          return state.computeControllerName(params, transition);
        } else {
          return state.getControllerName();
        }
      };

      return Dispatcher;

    })();
    Router.loadParamHelper = function() {
      return this.paramHelper || (this.paramHelper = new ParamHelper(this.paramHelperOptions));
    };
    ParamHelper = (function() {
      ParamHelper.include(StrictParameters);

      ParamHelper.prototype.reArrayIndex = /^[0-9]+$/;

      function ParamHelper(options) {
        this.mergeParams(options);
      }

      ParamHelper.prototype.refersToRegexMatch = function(param) {
        return this.reArrayIndex.test(param) || (param === 'index' || param === 'input');
      };

      ParamHelper.prototype.refersToQueryString = function(param) {
        return param === 'query';
      };

      ParamHelper.prototype.decode = function(param, value) {
        return decodeURIComponent(value);
      };

      ParamHelper.prototype.hashCode = function(string) {
        var char, hash, i, j, ref;
        hash = 0;
        for (i = j = 0, ref = string.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
          char = string.charCodeAt(i);
          hash = ((hash << 5) - hash) + char;
          hash = hash & hash;
        }
        return hash;
      };

      return ParamHelper;

    })();
    Router.loadControllerStore = function() {
      return this.controllerStore || (this.controllerStore = new ControllerStore(this.controllerStoreOptions));
    };
    ControllerStore = (function() {
      ControllerStore.include(StrictParameters);

      function ControllerStore(options) {
        this.mergeParams(options);
        this._classByName = {};
      }

      ControllerStore.prototype.getClass = function(name) {
        return this._classByName[name];
      };

      ControllerStore.prototype.registerClass = function(name, klass) {
        return this._classByName[name] = klass;
      };

      return ControllerStore;

    })();
    Router.createTransition = function(options) {
      return new Transition(options);
    };
    Transition = (function() {
      Transition.include(StrictParameters);

      Transition.param('fromState');

      Transition.param('toState', {
        required: true
      });

      Transition.param('fromParams');

      Transition.param('toParams', {
        alias: 'params'
      });

      Transition.param('route', {
        required: true
      });

      function Transition(options) {
        this.mergeParams(options);
      }

      Transition.prototype.prevent = function() {
        return this._prevented = true;
      };

      Transition.prototype.isPrevented = function() {
        return !!this._prevented;
      };

      return Transition;

    })();
    Router.loadHistory = function() {
      return this.history || (this.history = new History(this.historyOptions));
    };
    History = (function() {
      var bindMethod, extend, isEnabled, onceMethod;

      History.prototype.reFragment = /#(.*)$/;

      History.include(PublisherSubscriber);

      History.include(StrictParameters);

      History.prototype.options = function() {
        return {
          hashChange: true,
          interval: 50,
          load: true
        };
      };

      extend = _.extend, bindMethod = _.bindMethod, onceMethod = _.onceMethod, isEnabled = _.isEnabled;

      function History(options) {
        var ref;
        this.mergeParams(options);
        onceMethod(this, 'start');
        bindMethod(this, 'check');
        this.setGlobals();
        this.supportsPushState = ((ref = this.history) != null ? ref.pushState : void 0) != null;
        this.pushStateBased = this.supportsPushState && (this.options.pushState != null);
        this.hashChangeBased = !this.pushStateBased;
      }

      History.prototype.setGlobals = function() {
        var ref, ref1;
        this.document = (typeof document !== "undefined" && document !== null) && document;
        this.window = (typeof window !== "undefined" && window !== null) && window;
        this.location = (ref = this.window) != null ? ref.location : void 0;
        return this.history = (ref1 = this.window) != null ? ref1.history : void 0;
      };

      History.prototype.start = function() {
        this.route = this.getRoute();
        if (this.pushStateBased) {
          Router.$(this.window).on('popstate', this.check);
        } else if ('onhashchange' in this.window) {
          Router.$(this.window).on('hashchange', this.check);
        } else {
          setInterval(this.check, this.interval);
        }
        if (this.options.load) {
          return this.load({
            route: this.route
          });
        }
      };

      History.prototype.check = function(e) {
        var route;
        route = this.getRoute();
        if (route !== this.route) {
          return this.load({
            route: route
          });
        }
      };

      History.prototype.load = function(arg) {
        var fixed, fromParams, fromState, ref, result, route, toParams, toState, transition;
        route = arg.route;
        fixed = this._removeRouteAmbiguity(route);
        if (route !== fixed) {
          return this.navigate(fixed, {
            replace: true,
            load: true
          });
        }
        this.route = route;
        fromState = Router.currentState;
        fromParams = (ref = Router.previousTransition) != null ? ref.toParams : void 0;
        toState = Router.loadStateMatcher().match(route);
        toParams = (toState != null ? toState.extractParams(route) : void 0) || {};
        transition = Router.createTransition({
          fromState: fromState,
          fromParams: fromParams,
          toState: toState,
          toParams: toParams,
          route: route
        });
        result = Router.loadDispatcher().dispatch(transition);
        if (result) {
          Router.previousState = Router.currentState;
          Router.previousTransition = Router.currentTransition;
          Router.currentState = toState;
          Router.currentTransition = transition;
        }
        return result;
      };

      History.prototype.navigate = function(route, options) {
        var result;
        route = this._removeRouteAmbiguity(route);
        if (this.route === route) {
          return;
        }
        if (!options || options === true) {
          options = {
            load: !!options
          };
        }
        result = !options.load || this.load({
          route: route
        });
        if (result) {
          this.route = route;
          if (this.pushStateBased) {
            this._updatePath(route, options.replace);
          } else {
            this._updateFragment(route, options.replace);
          }
        }
        return result;
      };

      History.prototype.getPath = function() {
        return decodeURI(this.location.pathname + this.location.search);
      };

      History.prototype.getFragment = function() {
        var ref;
        return (((ref = this.location.href.match(this.reFragment)) != null ? ref[1] : void 0) || '') + this.location.search;
      };

      History.prototype.getRoute = function(options) {
        if (this.pushStateBased) {
          return this.getPath(options);
        } else {
          return this.getFragment(options);
        }
      };

      History.prototype._updatePath = function(route, replace) {
        var method;
        method = replace ? 'replaceState' : 'pushState';
        return this.history[method]({}, this.document.title, '/' + route);
      };

      History.prototype._updateFragment = function(route, replace) {
        var href;
        route = route.replace(/\?.*$/, '');
        if (replace) {
          href = location.href.replace(/#.*$/, '');
          location.replace(href + '#' + route);
        } else {
          location.hash = '#' + route;
        }
      };

      History.prototype._removeRouteAmbiguity = function(route) {
        route = indexOf.call(route, '?') >= 0 ? route.replace(/\/+\?/, '?') : route.replace(/\/+$/, '');
        return route.replace(/^\/+/, '');
      };

      return History;

    })();
    Router.loadLinksInterceptor = function() {
      return this.linksInterceptor || (this.linksInterceptor = new LinksInterceptor(this.linksInterceptorOptions));
    };
    LinksInterceptor = (function() {
      var bindMethod;

      LinksInterceptor.include(StrictParameters);

      LinksInterceptor.prototype.reUriScheme = /^(\w+):(?:\/\/)?/;

      bindMethod = _.bindMethod;

      function LinksInterceptor(options) {
        this.mergeParams(options);
        bindMethod(this, 'intercept');
      }

      LinksInterceptor.prototype.start = function() {
        return Router.$(document).on('click', 'a', this.intercept);
      };

      LinksInterceptor.prototype.intercept = function(e) {
        var $link, href, intercept, pathname, ref;
        if (e.which !== 1) {
          return;
        }
        $link = Router.$(e.currentTarget);
        if (!(href = $link.attr('href'))) {
          return;
        }
        intercept = (ref = $link.attr('intercept')) != null ? ref : $link.data('intercept');
        if (intercept === 'false') {
          return;
        }
        if (this.reUriScheme.test(href)) {
          return;
        }
        e.preventDefault();
        pathname = $link[0].pathname.replace(/^\//, '');
        return Router.loadHistory().navigate(pathname, true);
      };

      return LinksInterceptor;

    })();
    return _.extend(Router, {
      State: State,
      StateStore: StateStore,
      StateBuilder: StateBuilder,
      StateDefaultsAccess: StateDefaultsAccess,
      StateParametersExtract: StateParametersExtract,
      StateRouteAssemble: StateRouteAssemble,
      Dispatcher: Dispatcher,
      ControllerStore: ControllerStore,
      History: History,
      PathDecorator: PathDecorator,
      PatternCompiler: PatternCompiler,
      StateMatcher: StateMatcher,
      Transition: Transition,
      Pattern: Pattern,
      ParamHelper: ParamHelper
    });
  });

}).call(this);
