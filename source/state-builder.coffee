class StateBuilder extends BaseClass

  {extend} = _

  build: (name, base, data) ->
    if base
      name = base.name + '.' + name
      basePattern = base.pattern

    pattern = if data.path?
      Pattern.fromPath(data.path, base: basePattern)

    else if data.pattern?
      Pattern.fromRegexSource(data.pattern, base: basePattern)

    else if data['404']
      Pattern.fromRegexSource('.*', base: basePattern)

    else
      # TODO Error message
      throw new Error("Neither path nor pattern specified for state: '#{name}'")

    extend data, {name, base, pattern}

    new State(data)