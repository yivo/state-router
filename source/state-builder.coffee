class StateBuilder extends BaseClass

  build: (name, base, data) ->
    if base
      name = base.name + '.' + name
      basePattern = base.pattern

    if data['404'] and !data.pattern? and !data.path
      data.pattern = '.*'

    pattern = if data.pattern?
      Pattern.fromRegexSource(data.pattern, base: basePattern)

    else if data.path?
      Pattern.fromPath(data.path, base: basePattern)

    else
      throw new Error "[#{Router}] Neither path nor pattern specified for state #{name}"

    extend data, {name, base, pattern}

    new State(data)

  {extend} = _

{isObject, isString} = _

Router.createState = (name) ->
  length  = arguments.length
  base    = arguments[1] if length > 1

  if isObject(base) and base not instanceof State
    options = base
    base    = null
  else
    base    = Router.states.get(base) if isString(base)
    options = arguments[2] if length > 2

  Router.stateBuilder.build(name, base, options)
