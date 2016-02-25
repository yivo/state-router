class State extends CoreObject

  @include StateDefaultParameters
  @include StateRouteParameters
  @include StateRouteAssemble

  @param 'name',       required: yes
  @param 'pattern',    required: yes
  @param 'base'
  @param '404',        as: 'handles404'
  @param 'abstract'
  @param 'controller', as: 'controllerName'

  constructor: ->
    super
    @id         = _.generateID()
    @handles404 = !!@handles404
    @abstract   = !!@abstract
    @isRoot     = !@base

    if @abstract and @handles404
      throw new Error "[#{Router}] State can't handle 404 errors
        and be abstract at the same time"

    if @pattern.regexBased and not @ownRouteAssembler
      throw new Error "[#{Router}] To assemble #{@name} state's route from pattern which
        is based on regex you must define custom assembler"

  toString: ->
    "state #{@name}"

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

  @property 'depth', ->
    depth = 0
    state = this
    ++depth while state = state.base
    depth
