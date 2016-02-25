class PatternCompiler extends CoreObject

  rsQueryString:  '(?:\\?(?<query>([\\s\\S]*)))?'
  reQueryString:  XRegExp(this::rsQueryString + '$')
  leftBoundary:   '^'
  rightBoundary:  this::rsQueryString + '$'

  {isEnabled} = _

  compile: (source, options) ->
    XRegExp(@bound(source, options))

  bound: (source, options) ->
    starts = isEnabled(options, 'starts')
    ends   = isEnabled(options, 'ends')
    empty  = source is ''

    if starts
      source = @leftBoundary + source

      if empty and not ends
        source = source + @rsQueryString

    if ends
      source = source + @rightBoundary

    source
