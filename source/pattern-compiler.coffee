Router.loadPatternCompiler = ->
  @patternCompiler ||= new PatternCompiler(@pattermCompilerOptions)

class PatternCompiler

  @include StrictParameters

  rsQueryString: '(?:\\?(?<query>([\\s\\S]*)))?'
  reQueryString: XRegExp(@::rsQueryString + '$')
  leftBoundary: '^'
  rightBoundary: @::rsQueryString + '$'

  {isEnabled} = _

  constructor: (options) ->
    @mergeParams(options)

  compile: (source, options) ->
    XRegExp(@bound(source, options))

  bound: (source, options) ->
    starts = isEnabled(options, 'starts')
    ends   = isEnabled(options, 'ends')
    empty  = source is ''

    if starts
      source = @leftBoundary + source

      if empty and !ends
        source = source + @rsQueryString

    if ends
      source = source + @rightBoundary

    source