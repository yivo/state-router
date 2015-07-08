class State extends BaseClass

  @include StateDefaultParameters
  @include StateRouteParameters
  @include StateRouteAssemble

  @param 'name',       required: yes
  @param 'pattern',    required: yes
  @param 'base'
  @param '404',        as: 'is404'
  @param 'abstract',   as: 'isAbstract'
  @param 'controller', as: '_controllerClassName'

  {isFunction} = _

  constructor: ->
    super
    @is404      = !!@is404
    @isAbstract = !!@isAbstract
    @isRoot     = !@base

    if @isAbstract and @is404
      # TODO Error message
      throw new Error 'State can be either abstract or 404 or none'

    if not @is404 and @pattern.isRegexBased and not @ownRouteAssembler
      # TODO Error message
      throw new Error "[#{Router}] To assemble route from pattern which
        is based on regex you must define custom assembler. #{this}"

  toString: ->
    "#{@constructor.name} '#{@name}'"

  computeControllerClass: ->
    Class = if isFunction(@_controllerClassName)
      @_controllerClassName.apply(this, arguments)
    else
      @_controllerClassName

    if isString(Class)
      Class = Router.controllerStore.findClass(Class)
    Class

  @property 'root', ->
    state = this

    loop
      break if not state.base
      state = state.base

    if state isnt this
      state

  @property 'chain', ->
    chain = [this]
    state = this
    while state = state.base
      chain.unshift(state)
    chain