Router.on 'start', ->
  Router.linksInterceptor.start()

Router.on 'stop', ->
  Router.linksInterceptor.stop()

Router.reURIScheme = /^(\w+):(?:\/\/)?/

Router.matchURIScheme = (str) ->
  str?.match?(Router.reURIScheme)?[0]

class LinksInterceptor extends BaseClass

  constructor: ->
    super
    _.bindMethod(this, 'intercept')
    @started = false

  start: ->
    if @started
      throw new Error "[#{Router}] Links interceptor has already been started!"

    Router.$(document).on('click', 'a', @intercept)
    @started = true
    this

  stop: ->
    unless @started
      throw new Error "[#{Router}] Links interceptor hasn't been started!"

    Router.$(document).off('click', 'a', @intercept)
    @started = false
    this

  intercept: (e) ->
    # Only intercept left-clicks
    return if e.which isnt 1

    $link = Router.$(e.currentTarget)

    # Get the href
    # Stop processing if there isn't one
    return unless href = $link.attr('href')

    # Determine if we're supposed to bypass the link
    # based on its attributes
    intercept = $link.attr('intercept') ? $link.data('intercept')
    return if intercept is 'false'

    # Return if the URI is absolute, or if URI contains scheme
    return if Router.matchURIScheme(href)?

    # If we haven't been stopped yet, then we prevent the default action
    e.preventDefault()

    route = if Router.history.pushStateBased
      History.derivePath($link[0])
    else
      History.deriveFragment($link[0])

    Router.navigate(route, true)
    return