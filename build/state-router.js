(function() {
  var hasProp = {}.hasOwnProperty,
    extend1 = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  (function(root, factory) {
    if (typeof define === 'function' && define.amd) {
      define(['lodash', 'jquery', 'XRegExp', 'construct-with', 'publisher-subscriber', 'property-accessors', 'yess', 'ize', 'coffee-concerns'], function(_, $, XRegExpAPI, ConstructWith, PublisherSubscriber, PropertyAccessors) {
        return root.StateRouter = factory(root, _, $, XRegExpAPI, ConstructWith, PublisherSubscriber, PropertyAccessors);
      });
    } else if (typeof module === 'object' && typeof module.exports === 'object') {
      module.exports = factory(root, require('lodash'), require('jquery'), require('XRegExp'), require('construct-with'), require('publisher-subscriber'), require('property-accessors'), require('yess'), require('ize'), require('coffee-concerns'));
    } else {
      root.StateRouter = factory(root, root._, root.$, root.XRegExp, root.ConstructWith, root.PublisherSubscriber, root.PropertyAccessors);
    }
  })(this, function(__root__, _, $, XRegExpAPI, ConstructWith, PublisherSubscriber, PropertyAccessors) {
    var BaseClass, Dispatcher, History, LinksInterceptor, ParamHelper, PathDecorator, Pattern, PatternCompiler, Router, State, StateBuilder, StateDefaultParameters, StateMatcher, StateRouteAssemble, StateRouteParameters, StateStore, StateStoreFrameworkFeatures, Transition, XRegExp;
    XRegExp = XRegExpAPI.XRegExp || XRegExpAPI;
    Router = {};
    (function() {
      var define, k, len, name, names, ref;
      names = 'history linksInterceptor paramHelper pathDecorator patternCompiler stateBuilder dispatcher stateMatcher stateStore';
      define = function(name) {
        var className, keyName, loadName;
        keyName = "_" + name;
        loadName = "load" + (name.capitalize());
        className = name.classCase();
        Router[loadName] = function() {
          return Router[keyName] || (Router[keyName] = new Router[className](_.result(Router, name + "Options")));
        };
        return PropertyAccessors.property(Router, name, {
          readonly: true,
          get: loadName
        });
      };
      ref = names.split(/\s+/);
      for (k = 0, len = ref.length; k < len; k++) {
        name = ref[k];
        define(name);
      }
      PropertyAccessors.property(Router, 'states', {
        readonly: true,
        get: 'loadStateStore'
      });
    })();
    StateDefaultParameters = {
      included: function(Class) {
        Class.param('defaults', {
          as: '_ownDefaults'
        });
        Class.property('ownDefaults', function() {
          if (_.isFunction(this._ownDefaults)) {
            this._ownDefaults = this._ownDefaults();
          }
          if (!_.isObject(this._ownDefaults)) {
            this._ownDefaults = {};
          }
          return this._ownDefaults;
        });
        return Class.property('defaults', function() {
          var defaults, param, params, state, value;
          state = this;
          params = {};
          while (state) {
            defaults = state.ownDefaults;
            if (defaults) {
              for (param in defaults) {
                value = defaults[param];
                if (params[param] == null) {
                  params[param] = value;
                }
              }
            }
            state = state.base;
          }
          return params;
        });
      }
    };
    StateRouteParameters = {
      extractParams: function(route) {
        var helper, match, param, params, value;
        helper = Router.paramHelper;
        match = this.pattern.match(route);
        params = _.extend({}, this.defaults);
        for (param in match) {
          if (!hasProp.call(match, param)) continue;
          value = match[param];
          if (!helper.refersToRegexMatch(param)) {
            if (value != null) {
              params[param] = helper.refersToQueryString(param) ? value : helper.decode(param, value);
            }
          }
        }
        return params;
      },
      identityParams: function(route) {
        var helper, match, param, params, value;
        helper = Router.paramHelper;
        match = this.pattern.identity(route);
        params = _.extend({}, this.defaults);
        params.query = this.extractQueryString(route);
        for (param in match) {
          if (!hasProp.call(match, param)) continue;
          value = match[param];
          if ((value != null) && !helper.refersToRegexMatch(param)) {
            params[param] = helper.decode(param, value);
          }
        }
        return params;
      },
      extractQueryString: function(route) {
        var ref;
        return (ref = XRegExp.exec(route, Router.patternCompiler.reQueryString)) != null ? ref.query : void 0;
      }
    };
    StateRouteParameters.params = StateRouteParameters.extractParams;
    StateRouteAssemble = {
      included: function(Class) {
        Class.param('assembler', {
          as: 'ownRouteAssembler'
        });
        return Class.param('paramAssembler');
      },
      paramAssembler: function(params, match, optional, token, splat, param) {
        var paramHelper, ref, value;
        value = (ref = params != null ? params[param] : void 0) != null ? ref : this.defaults[param];
        if (value == null) {
          if (!optional) {
            throw "[" + Router + "] Parameter '" + param + "' is required to assemble " + this.name + " state's route";
          }
          return '';
        }
        paramHelper = Router.paramHelper;
        return (token || '') + (splat ? paramHelper.encodeSplat(param, value) : paramHelper.encode(param, value));
      },
      assembleRoute: function(params) {
        var own, query, route, state;
        state = this;
        route = '';
        while (state) {
          own = state.assembleOwnRoute(params);
          route = route ? own + (own ? '/' : '') + route : own;
          state = state.base;
        }
        if ((query = params != null ? params.query : void 0) != null) {
          if (!_.isString(query)) {
            query = decodeURIComponent(Router.$.param(query));
          }
          route = route + (query[0] === '?' ? '' : '?') + query;
        }
        return route;
      },
      assembleOwnRoute: function(params) {
        var assembler, own, path;
        if (assembler = this.ownRouteAssembler) {
          own = assembler.call(this, _.extend({}, this.ownDefaults, params), this);
        } else {
          path = this.pattern.ownPath;
          own = Router.pathDecorator.replaceParams(path, _.bind(this.paramAssembler, this, params));
        }
        return own;
      }
    };
    StateRouteAssemble.route = StateRouteAssemble.assembleRoute;
    StateStoreFrameworkFeatures = (function() {
      var Concern, key, ref, value;
      Concern = {};
      ref = {
        Before: 0,
        After: 1
      };
      for (key in ref) {
        value = ref[key];
        Concern['insert' + key] = (function(type, offset) {
          return function(state, insertedState) {
            var _newState, _state, i, j;
            _state = this.get(state);
            _newState = this.get(insertedState);
            i = this.indexOf(_state);
            j = this.indexOf(_newState);
            if (i < 0) {
              throw new Error("[" + Router + "] Can't insert " + _newState + " " + type + " " + _state + " because " + _state + " does not exist in store");
            }
            if (j > -1) {
              _.removeAt(this, j);
            }
            _.insertAt(this, i + offset, _newState);
            return this;
          };
        })(key.toLowerCase(), value);
      }
      return Concern;
    })();
    _.extend(Router, PublisherSubscriber.InstanceMembers);
    Router.$ = $;
    Router.toString = function() {
      return 'StateRouter';
    };
    Router.start = function() {
      Router.notify('debug');
      return Router.notify('start');
    };
    Router.stop = function() {
      return Router.notify('stop');
    };
    Router.url = function(state, params) {
      var c;
      c = Router.history.pushStateBased ? '/' : '#';
      return c + Router.states.fetch(state).route(params);
    };
    Router.go = function(state, params) {
      return Router.navigate(Router.url(state, params), true);
    };
    Router["switch"] = function(state, params) {
      return Router.go(state, _.extend({}, Router.currentParams, params));
    };
    Router.navigate = function(route, options) {
      return Router.history.navigate(route, options);
    };
    Router.transition = function(state, params) {
      var fromParams, fromRoute, fromState, toParams, toRoute, toState, transition;
      fromState = Router.currentState;
      fromParams = Router.currentParams;
      fromRoute = Router.currentRoute;
      toState = Router.states.fetch(state);
      toParams = params || {};
      toRoute = Router.history.route;
      transition = new Transition({
        fromState: fromState,
        fromParams: fromParams,
        fromRoute: fromRoute,
        toState: toState,
        toParams: toParams,
        toRoute: toRoute
      });
      return transition.dispatch();
    };
    Router.controllerLookupNamespace = this;
    Router.controllerLookup = function(name) {
      var ns;
      ns = _.result(Router, 'controllerLookupNamespace');
      return ns[name + "Controller"] || ns[name] || ns[(name.classCase()) + "Controller"] || ns[name.classCase()];
    };
    Router.findController = function(arg) {
      var Class, index, length, rest;
      if (typeof arg === 'function') {
        length = arguments.length;
        rest = Array(Math.max(length - 1, 0));
        index = 0;
        while (++index < length) {
          rest[index - 1] = arguments[index];
        }
        Class = arg.apply(null, rest);
      } else {
        Class = Router.controllerLookup(arg);
      }
      if (typeof Class === 'string') {
        Class = Router.controllerLookup(Class);
      }
      return Class;
    };
    BaseClass = (function() {
      BaseClass.include(ConstructWith);

      function BaseClass(options) {
        this.constructWith(options);
      }

      return BaseClass;

    })();
    State = (function(superClass) {
      extend1(State, superClass);

      State.include(StateDefaultParameters);

      State.include(StateRouteParameters);

      State.include(StateRouteAssemble);

      State.param('name', {
        required: true
      });

      State.param('pattern', {
        required: true
      });

      State.param('base');

      State.param('404', {
        as: 'handles404'
      });

      State.param('abstract');

      State.param('controller', {
        as: 'controllerName'
      });

      function State() {
        State.__super__.constructor.apply(this, arguments);
        this.id = _.generateId();
        this.handles404 = !!this.handles404;
        this.abstract = !!this.abstract;
        this.isRoot = !this.base;
        if (this.abstract && this.handles404) {
          throw new Error("[" + Router + "] State can't handle 404 errors and be abstract at the same time");
        }
        if (this.pattern.regexBased && !this.ownRouteAssembler) {
          throw new Error("[" + Router + "] To assemble " + this.name + " state's route from pattern which is based on regex you must define custom assembler");
        }
      }

      State.prototype.toString = function() {
        return "state " + this.name;
      };

      State.property('root', function() {
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
      });

      State.property('chain', function() {
        var chain, state;
        chain = [this];
        state = this;
        while (state = state.base) {
          chain.unshift(state);
        }
        return chain;
      });

      State.property('depth', function() {
        var depth, state;
        depth = 0;
        state = this;
        while (state = state.base) {
          ++depth;
        }
        return depth;
      });

      return State;

    })(BaseClass);
    StateStore = (function(superClass) {
      extend1(StateStore, superClass);

      StateStore.include(StateStoreFrameworkFeatures);

      StateStore.prototype.length = 0;

      function StateStore() {
        StateStore.__super__.constructor.apply(this, arguments);
        this._byName = {};
      }

      StateStore.prototype.push = function(state) {
        if (this.indexOf(state) === -1) {
          Array.prototype.push.call(this, state);
          this._byName[state.name] = state;
        }
        return this;
      };

      StateStore.prototype.get = function(state) {
        if (_.isObject(state)) {
          return state;
        } else {
          return this._byName[state];
        }
      };

      StateStore.prototype.fetch = function(state) {
        var _state;
        _state = this.get(state);
        if (!_state) {
          throw new Error("[" + Router + "] State " + state + " does not exist!");
        }
        return _state;
      };

      StateStore.prototype.findOne = function(predicate, context) {
        var k, len, state;
        for (k = 0, len = this.length; k < len; k++) {
          state = this[k];
          if (predicate.call(context, state)) {
            return state;
          }
        }
      };

      StateStore.prototype.indexOf = function(state) {
        var _state, i, k, len, obj;
        _state = this.get(state);
        for (i = k = 0, len = this.length; k < len; i = ++k) {
          obj = this[i];
          if (obj === _state) {
            return i;
          }
        }
        return -1;
      };

      StateStore.prototype.map = function(callback) {
        var parentsStack, thisApi;
        parentsStack = [];
        thisApi = function(name) {
          var base, children, length, options, state;
          length = arguments.length;
          if (length > 1 && _.isFunction(arguments[1])) {
            children = arguments[1];
            state = Router.states.get(name);
          } else if (length > 1 && _.isObject(arguments[1])) {
            options = arguments[1];
            base = _.last(parentsStack);
            state = Router.createState(name, base, options);
            if (length > 2) {
              children = arguments[2];
            }
            Router.stateStore.push(state);
          }
          if (children) {
            parentsStack.push(state);
            children();
            parentsStack.pop();
          }
          return Router;
        };
        return callback(thisApi);
      };

      return StateStore;

    })(BaseClass);
    StateBuilder = (function(superClass) {
      extend1(StateBuilder, superClass);

      function StateBuilder() {
        return StateBuilder.__super__.constructor.apply(this, arguments);
      }

      StateBuilder.prototype.build = function(name, base, data) {
        var basePattern, pattern;
        if (base) {
          name = base.name + '.' + name;
          basePattern = base.pattern;
        }
        if (data['404'] && (data.pattern == null) && !data.path) {
          data.pattern = '.*';
        }
        pattern = (function() {
          if (data.pattern != null) {
            return Pattern.fromRegexSource(data.pattern, {
              base: basePattern
            });
          } else if (data.path != null) {
            return Pattern.fromPath(data.path, {
              base: basePattern
            });
          } else {
            throw new Error("[" + Router + "] Neither path nor pattern specified for state " + name);
          }
        })();
        _.extend(data, {
          name: name,
          base: base,
          pattern: pattern
        });
        return new State(data);
      };

      return StateBuilder;

    })(BaseClass);
    Router.createState = function(name) {
      var base, length, options;
      length = arguments.length;
      if (length > 1) {
        base = arguments[1];
      }
      if (_.isPlainObject(base)) {
        options = base;
        base = null;
      } else {
        if (_.isString(base)) {
          base = Router.states.get(base);
        }
        if (length > 2) {
          options = arguments[2];
        }
      }
      return Router.stateBuilder.build(name, base, options);
    };
    StateMatcher = (function(superClass) {
      extend1(StateMatcher, superClass);

      function StateMatcher() {
        return StateMatcher.__super__.constructor.apply(this, arguments);
      }

      StateMatcher.prototype.match = function(route) {
        var match, states;
        states = Router.states;
        match = states.findOne(function(state) {
          return !state.abstract && !state.handles404 && state.pattern.test(route);
        });
        match || (match = states.findOne(function(state) {
          return state.handles404;
        }));
        if (!match) {
          throw new Error("[" + Router + "] None of states matched route '" + route + "' and no 404 state was found");
        }
        return match;
      };

      return StateMatcher;

    })(BaseClass);
    Pattern = (function(superClass) {
      var extend;

      extend1(Pattern, superClass);

      Pattern.param('base');

      Pattern.param('source', {
        as: 'source',
        required: true
      });

      Pattern.param('path', {
        as: 'ownPath'
      });

      extend = _.extend;

      function Pattern() {
        var baseSource, compiler, ref;
        Pattern.__super__.constructor.apply(this, arguments);
        if (baseSource = (ref = this.base) != null ? ref.source : void 0) {
          this.source = baseSource + (this.source ? '/' + this.source : '');
        }
        this.type = this.ownPath != null ? 'path' : 'regex';
        this.regexBased = this.type === 'regex';
        this.pathBased = this.type === 'path';
        compiler = Router.patternCompiler;
        this.reRoute = compiler.compile(this.source, {
          starts: true,
          ends: true
        });
        this.reRouteIdentity = compiler.compile(this.source, {
          starts: true,
          ends: false
        });
      }

      Pattern.prototype.test = function(route) {
        return this.reRoute.test(route);
      };

      Pattern.prototype.match = function(route) {
        return XRegExp.exec(route, this.reRoute);
      };

      Pattern.prototype.identity = function(route) {
        return XRegExp.exec(route, this.reRouteIdentity);
      };

      Pattern.fromPath = function(path, options) {
        var decorator, source;
        decorator = Router.pathDecorator;
        source = decorator.preprocessParams(decorator.escape(path));
        return this.fromRegexSource(source, extend({}, options, {
          path: path
        }));
      };

      Pattern.fromRegexSource = function(source, options) {
        return new this(extend({}, options, {
          source: source
        }));
      };

      return Pattern;

    })(BaseClass);
    PatternCompiler = (function(superClass) {
      var isEnabled;

      extend1(PatternCompiler, superClass);

      function PatternCompiler() {
        return PatternCompiler.__super__.constructor.apply(this, arguments);
      }

      PatternCompiler.prototype.rsQueryString = '(?:\\?(?<query>([\\s\\S]*)))?';

      PatternCompiler.prototype.reQueryString = XRegExp(PatternCompiler.prototype.rsQueryString + '$');

      PatternCompiler.prototype.leftBoundary = '^';

      PatternCompiler.prototype.rightBoundary = PatternCompiler.prototype.rsQueryString + '$';

      isEnabled = _.isEnabled;

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

    })(BaseClass);
    PathDecorator = (function(superClass) {
      extend1(PathDecorator, superClass);

      function PathDecorator() {
        return PathDecorator.__super__.constructor.apply(this, arguments);
      }

      PathDecorator.params('paramPreprocessor', 'reEscape', 'escapeReplacement');

      PathDecorator.prototype.reEscape = /[\-{}\[\]+?.,\\\^$|#\s]/g;

      PathDecorator.prototype.reParam = /(\()?(.)?(\*)?:(\w+)\)?/g;

      PathDecorator.prototype.escapeReplacement = '\\$&';

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

    })(BaseClass);
    Dispatcher = (function(superClass) {
      extend1(Dispatcher, superClass);

      function Dispatcher() {
        return Dispatcher.__super__.constructor.apply(this, arguments);
      }

      Dispatcher.prototype.dispatch = function(transition) {
        var work;
        work = (function(_this) {
          return function() {
            var currentState, currentStateChain, enterStates, ignoreStates, k, l, leaveStates, len, len1, nextState, nextStateChain, state;
            _this.dispatcherTransition = transition;
            Router.notify('transitionStart', transition);
            if (transition.prevented) {
              _this.dispatcherTransition = null;
              Router.notify('transitionPrevent', transition);
              return;
            } else if (transition.aborted) {
              _this.dispatcherTransition = null;
              Router.notify('transitionAbort', transition);
              return;
            }
            currentState = Router.currentState;
            currentStateChain = (currentState != null ? currentState.chain : void 0) || [];
            nextState = transition.state;
            nextStateChain = (nextState != null ? nextState.chain : void 0) || [];
            enterStates = [];
            leaveStates = [];
            ignoreStates = [];
            for (k = 0, len = currentStateChain.length; k < len; k++) {
              state = currentStateChain[k];
              if (indexOf.call(nextStateChain, state) >= 0) {
                if (_this.mustReloadState(state, transition)) {
                  leaveStates.unshift(state);
                  enterStates.push(state);
                } else {
                  ignoreStates.push(state);
                }
              } else {
                leaveStates.unshift(state);
              }
            }
            for (l = 0, len1 = nextStateChain.length; l < len1; l++) {
              state = nextStateChain[l];
              if ((indexOf.call(enterStates, state) < 0) && (indexOf.call(ignoreStates, state) < 0)) {
                enterStates.push(state);
              }
            }
            while (state = leaveStates.shift()) {
              _this.leaveState(state, transition);
              if (transition.aborted) {
                _this.dispatcherTransition = null;
                Router.notify('transitionAbort', transition);
                return;
              }
            }
            while (state = enterStates.shift()) {
              _this.enterState(state, transition);
              if (transition.aborted) {
                _this.dispatcherTransition = null;
                Router.notify('transitionAbort', transition);
                return;
              }
            }
            _this.dispatcherTransition = null;
            return Router.notify('transitionSuccess', transition);
          };
        })(this);
        if (this.dispatcherTransition) {
          this.dispatcherTransition.abort();
          _.delay(work);
        } else {
          work();
        }
      };

      Dispatcher.prototype.enterState = function(state, transition) {
        var controller, ctrlClass, parentCtrl, ref, rootCtrl, rootState;
        Router.notify('stateEnterStart', state, transition);
        if (transition.aborted) {
          Router.notify('stateEnterAbort', state, transition);
          return;
        }
        ctrlClass = Router.findController(state.controllerName, transition.params, transition);
        if (ctrlClass) {
          rootState = state.root;
          rootCtrl = rootState != null ? rootState.__controller : void 0;
          parentCtrl = (ref = state.base) != null ? ref.__controller : void 0;
          ctrlClass = _.beforeConstructor(ctrlClass, function() {
            this.rootController = rootCtrl || void 0;
            return this.parentController = parentCtrl || void 0;
          });
          controller = new ctrlClass(transition.params, transition);
          if (typeof controller.enter === "function") {
            controller.enter(transition.toParams, transition);
          }
        }
        if (transition.aborted) {
          if (controller != null) {
            if (typeof controller.leave === "function") {
              controller.leave();
            }
          }
          Router.notify('stateEnterAbort', state, transition);
        } else {
          state.__controller = controller;
          state.__paramsIdentity = state.identityParams(transition.route);
          Router.notify('stateEnterSuccess', state, transition);
        }
      };

      Dispatcher.prototype.leaveState = function(state, transition) {
        var controller;
        Router.notify('stateLeaveStart', state, transition);
        if (transition.aborted) {
          Router.notify('stateLeaveAbort', state, transition);
          return;
        }
        controller = state.__controller;
        if (controller != null) {
          if (typeof controller.leave === "function") {
            controller.leave(transition.params, transition);
          }
        }
        if (transition.aborted) {
          Router.notify('stateLeaveAbort', state, transition);
          return;
        } else {
          delete state.__paramsIdentity;
          delete state.__controller;
          Router.notify('stateLeaveSuccess', state, transition);
        }
      };

      Dispatcher.prototype.mustReloadState = function(state, transition) {
        var a, b, ref;
        a = state.__paramsIdentity;
        b = state.identityParams(transition.route);
        return false === (((ref = Router.options) != null ? ref.reloadOnQueryChange : void 0) !== true ? _.isEqual(_.omit(a, 'query'), _.omit(b, 'query')) : _.isEqual(a, b));
      };

      return Dispatcher;

    })(BaseClass);
    ParamHelper = (function(superClass) {
      extend1(ParamHelper, superClass);

      function ParamHelper() {
        return ParamHelper.__super__.constructor.apply(this, arguments);
      }

      ParamHelper.prototype.reArrayIndex = /^[0-9]+$/;

      ParamHelper.prototype.refersToRegexMatch = function(param) {
        return this.reArrayIndex.test(param) || (param === 'index' || param === 'input');
      };

      ParamHelper.prototype.refersToQueryString = function(param) {
        return param === 'query';
      };

      ParamHelper.prototype.encode = function(param, value) {
        return encodeURIComponent(value);
      };

      ParamHelper.prototype.encodeSplat = function(param, value) {
        return encodeURI(value);
      };

      ParamHelper.prototype.decode = function(param, value) {
        return decodeURIComponent(value);
      };

      return ParamHelper;

    })(BaseClass);
    Transition = (function(superClass) {
      extend1(Transition, superClass);

      Transition.param('fromState');

      Transition.param('fromParams');

      Transition.param('fromRoute');

      Transition.param('toState', {
        alias: 'state',
        required: true
      });

      Transition.param('toParams', {
        alias: 'params',
        required: true
      });

      Transition.param('toRoute', {
        alias: 'route',
        required: true
      });

      function Transition() {
        Transition.__super__.constructor.apply(this, arguments);
        this.prevented = false;
        this.aborted = false;
      }

      Transition.prototype.prevent = function() {
        if (!this.aborted && !this.prevented) {
          this.prevented = true;
          this.previouslyPrevented = true;
        }
        return this;
      };

      Transition.prototype.abort = function() {
        if (!this.aborted && !this.prevented) {
          this.aborted = true;
          this.previouslyAborted = true;
        }
        return this;
      };

      Transition.prototype.dispatch = function() {
        return Router.dispatcher.dispatch(this);
      };

      Transition.prototype.retry = function() {
        this.prevented = false;
        this.aborted = false;
        return this.dispatch();
      };

      Transition.prototype.toString = function() {
        var s;
        s = "transition";
        s += this.fromState ? " " + this.fromState.name : ' <initial>';
        s += " -> " + this.toState.name;
        return s;
      };

      return Transition;

    })(BaseClass);
    Router.on('start', function() {
      return _.delay(function() {
        return Router.history.start();
      });
    });
    Router.on('stop', function() {
      return _.delay(function() {
        return Router.history.stop();
      });
    });
    History = (function(superClass) {
      extend1(History, superClass);

      History.derivePath = function(obj) {
        return decodeURI((obj.pathname + obj.search).replace(/%25/g, '%2525')).replace(/^\/+/, '');
      };

      History.deriveFragment = function(obj) {
        var ref;
        return (((ref = obj.href.match(/#(.*)$/)) != null ? ref[1] : void 0) || '') + obj.search;
      };

      History.normalizeRoute = function(route) {
        var pre;
        pre = indexOf.call(route, '?') >= 0 ? route.replace(/\/+\?/, '?') : route.replace(/\/+$/, '');
        return pre.replace(/^(\/|#)+/, '');
      };

      function History() {
        var ref, ref1, ref2;
        this.options = {};
        this.options.load = true;
        this.options.interval = 50;
        History.__super__.constructor.apply(this, arguments);
        _.onceMethod(this, 'start');
        _.bindMethod(this, 'check');
        this.document = (typeof document !== "undefined" && document !== null) && document;
        this.window = (typeof window !== "undefined" && window !== null) && window;
        this.location = (ref = this.window) != null ? ref.location : void 0;
        this.history = (ref1 = this.window) != null ? ref1.history : void 0;
        this.supportsPushState = ((ref2 = this.history) != null ? ref2.pushState : void 0) != null;
        this.supportsHashChange = 'onhashchange' in this.window;
        this.pushStateBased = this.supportsPushState && this.options.pushState !== false;
        this.hashChangeBased = !this.pushStateBased && this.supportsHashChange && this.options.hashChange !== false;
        this.started = false;
      }

      History.property('path', function() {
        return this.constructor.derivePath(this.location);
      });

      History.property('fragment', function() {
        return this.constructor.deriveFragment(this.location);
      });

      History.property('route', function() {
        if (this.pushStateBased) {
          return this.path;
        } else {
          return this.fragment;
        }
      });

      History.prototype.start = function() {
        this.ensureNotStarted();
        if (this.pushStateBased) {
          Router.$(this.window).on('popstate', this.check);
        } else if (this.hashChangeBased) {
          Router.$(this.window).on('hashchange', this.check);
        } else {
          this._intervalId = setInterval(this.check, this.options.interval);
        }
        this.started = true;
        if (this.options.load) {
          this.load(this.route);
        }
        return this;
      };

      History.prototype.stop = function() {
        this.ensureStarted();
        Router.$(this.window).off('popstate', this.check);
        Router.$(this.window).off('hashchange', this.check);
        if (this._intervalId) {
          clearInterval(this._intervalId);
          this._intervalId = null;
        }
        this.started = false;
        return this;
      };

      History.prototype.check = function(e) {
        if (this.ensureStarted() && this.route !== this.loadedRoute) {
          this.load(this.route);
        }
        return this;
      };

      History.prototype.load = function(route) {
        var normalized;
        this.ensureStarted();
        normalized = this.constructor.normalizeRoute(route);
        if (route !== normalized) {
          return this.navigate(normalized, {
            replace: true,
            load: true
          });
        }
        this.loadedRoute = route;
        Router.notify('routeChange', route);
        return true;
      };

      History.prototype.navigate = function(route, options) {
        this.ensureStarted();
        route = this.constructor.normalizeRoute(route);
        if (route !== this.loadedRoute) {
          this.loadedRoute = route;
          if (!options || options === true) {
            options = {
              load: !!options
            };
          }
          if (this.pushStateBased) {
            this._updatePath(route, options.replace);
          } else {
            this._updateFragment(route, options.replace);
          }
          return !options.load || this.load(route);
        } else {
          return false;
        }
      };

      History.prototype._updatePath = function(route, replace) {
        var method;
        method = replace ? 'replaceState' : 'pushState';
        this.history[method]({}, this.document.title, '/' + route);
        Router.notify('pathUpdate', route, replace);
      };

      History.prototype._updateFragment = function(route, replace) {
        var href;
        route = route.replace(/\?.*$/, '');
        if (replace) {
          href = this.location.href.replace(/(javascript:|#).*$/, '');
          this.location.replace(href + '#' + route);
        } else {
          this.location.hash = '#' + route;
        }
        Router.notify('fragmentUpdate', replace);
      };

      History.prototype.ensureStarted = function() {
        if (!this.started) {
          throw new Error("[" + Router + "] History hasn't been started!");
        }
        return true;
      };

      History.prototype.ensureNotStarted = function() {
        if (this.started) {
          throw new Error("[" + Router + "] History has already been started!");
        }
        return true;
      };

      return History;

    })(BaseClass);
    Router.on('start', function() {
      return Router.linksInterceptor.start();
    });
    Router.on('stop', function() {
      return Router.linksInterceptor.stop();
    });
    Router.reURIScheme = /^(\w+):(?:\/\/)?/;
    Router.matchURIScheme = function(str) {
      var ref;
      return str != null ? typeof str.match === "function" ? (ref = str.match(Router.reURIScheme)) != null ? ref[0] : void 0 : void 0 : void 0;
    };
    LinksInterceptor = (function(superClass) {
      extend1(LinksInterceptor, superClass);

      function LinksInterceptor() {
        LinksInterceptor.__super__.constructor.apply(this, arguments);
        _.bindMethod(this, 'intercept');
        this.started = false;
      }

      LinksInterceptor.prototype.start = function() {
        if (this.started) {
          throw new Error("[" + Router + "] Links interceptor has already been started!");
        }
        Router.$(document).on('click', 'a', this.intercept);
        this.started = true;
        return this;
      };

      LinksInterceptor.prototype.stop = function() {
        if (!this.started) {
          throw new Error("[" + Router + "] Links interceptor hasn't been started!");
        }
        Router.$(document).off('click', 'a', this.intercept);
        this.started = false;
        return this;
      };

      LinksInterceptor.prototype.intercept = function(e) {
        var $link, href, intercept, ref, route;
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
        if (Router.matchURIScheme(href) != null) {
          return;
        }
        e.preventDefault();
        route = Router.history.pushStateBased ? History.derivePath($link[0]) : History.deriveFragment($link[0]);
        Router.navigate(route, true);
      };

      return LinksInterceptor;

    })(BaseClass);
    if (!_.isFunction(console.debug)) {
      console.debug = (function() {});
    }
    Router.on('routeChange', (function() {
      var firstChange;
      firstChange = true;
      return function(route) {
        if (firstChange) {
          console.debug("[" + Router + "] Bootstrap with route '" + route + "'");
          return firstChange = false;
        } else {
          return console.debug("[" + Router + "] Route changed '" + route + "'");
        }
      };
    })());
    Router.on('routeChange', function(route) {
      var state;
      state = Router.stateMatcher.match(route);
      return Router.transition(state, state.params(route), route);
    });
    Router.on('fragmentUpdate', function(fragment, replace) {
      return console.debug(("[" + Router + "] ") + (replace ? "Replaced hash in history with '" + fragment + "'" : "Set hash to history '" + fragment + "'"));
    });
    Router.on('pathUpdate', function(path, replace) {
      return console.debug(("[" + Router + "] ") + (replace ? "Replaced path in history with '" + path + "'" : "Pushed path to history '" + path + "'"));
    });
    Router.on('transitionStart', function(transition) {
      var action;
      action = transition.previouslyPrevented ? 'Retrying previously prevented' : transition.previouslyAborted ? 'Retrying previously aborted' : 'Started';
      console.debug("[" + Router + "] " + action + " " + transition);
      return console.debug("[" + Router + "] Parameters", transition.params);
    });
    Router.on('transitionAbort', function(transition) {
      return console.debug("[" + Router + "] Aborted " + transition);
    });
    Router.on('transitionPrevent', function(transition) {
      return console.debug("[" + Router + "] Prevented " + transition);
    });
    Router.on('transitionSuccess', function(transition) {
      Router.currentParams = transition.params;
      return Router.currentRoute = transition.route;
    });
    Router.on('transitionSuccess', function(transition) {
      return console.debug("[" + Router + "] Succeed " + transition);
    });
    Router.on('stateEnterAbort', function(state) {
      return console.debug("[" + Router + "] " + (_.repeat('  ', state.depth + 1)) + "Aborted " + state);
    });
    Router.on('stateEnterSuccess', function(state) {
      return console.debug("[" + Router + "] " + (_.repeat('  ', state.depth + 1)) + "Succeed " + state);
    });
    Router.on('stateEnterSuccess', function(state) {
      Router.currentState = state;
      return Router.notify('stateChange', state);
    });
    Router.on('stateEnterStart', function(state) {
      return console.debug("[" + Router + "] " + (_.repeat('  ', state.depth)) + "Entering " + state + "...");
    });
    Router.on('stateLeaveAbort', function(state) {
      return console.debug("[" + Router + "] " + (_.repeat('  ', state.depth + 1)) + "Aborted " + state);
    });
    Router.on('stateLeaveSuccess', function(state) {
      return console.debug("[" + Router + "] " + (_.repeat('  ', state.depth + 1)) + "Succeed " + state);
    });
    Router.on('stateLeaveSuccess', function(state) {
      return Router.currentState = state.base;
    });
    Router.on('stateLeaveStart', function(state) {
      return console.debug("[" + Router + "] " + (_.repeat('  ', state.depth)) + "Leaving " + state + "...");
    });
    _.extend(Router, {
      State: State,
      StateStore: StateStore,
      StateBuilder: StateBuilder,
      StateDefaultParameters: StateDefaultParameters,
      StateRouteParameters: StateRouteParameters,
      StateRouteAssemble: StateRouteAssemble,
      StateStoreFrameworkFeatures: StateStoreFrameworkFeatures,
      Dispatcher: Dispatcher,
      History: History,
      PathDecorator: PathDecorator,
      PatternCompiler: PatternCompiler,
      StateMatcher: StateMatcher,
      Transition: Transition,
      Pattern: Pattern,
      ParamHelper: ParamHelper,
      LinksInterceptor: LinksInterceptor
    });
    return Router;
  });

}).call(this);
