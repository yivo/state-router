Router.loadStateBuilder = ->
  @stateBuilder ||= new StateBuilder(@stateBuilderOptions)

class StateBuilder

  @include StrictParameters

  {extend} = _

  constructor: (options) ->
    @mergeParams(options)

  build: (name, base, data) ->
    if base
      name = base.getName() + '.' + name
      basePattern = base.pattern

    pattern = if data.path?
      Pattern.fromPath(data.path, base: basePattern)

    else if data.pattern?
      Pattern.fromRegex(data.pattern, base: basePattern)

    else if data['404']
      Pattern.fromRegex('.*', base: basePattern)

    else
      throw new Error("Neither path nor pattern specified for state: '#{name}'")

    extend data, {name, base, pattern}

    Router.createState(data)