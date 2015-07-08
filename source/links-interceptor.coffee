class LinksInterceptor extends BaseClass

  {bindMethod} = _

  constructor: ->
    super
    bindMethod(this, 'intercept')
    @started = false

  start: ->
    unless @started
      Router.$(document).on('click', 'a', @intercept)
      @started = true
    this

  stop: ->
    if @started
      Router.$(document).off('click', 'a', @intercept)
      @started = false
    this

  intercept: (e) ->
    # Only intercept left-clicks
    return if e.which isnt 1

    $link = Router.$(e.currentTarget)

    # Get the href; stop processing if there isn't one
    return unless href = $link.attr('href')

    # Determine if we're supposed to bypass the link
    # based on its attributes

    intercept = $link.attr('intercept') ? $link.data('intercept')
    return if intercept is 'false'

    # Return if the URL is absolute, or if the protocol is mailto or javascript
    return if Router.matchUriScheme(href)?

    # If we haven't been stopped yet, then we prevent the default action
    e.preventDefault()

    # Get the computed pathname of the link, removing
    # the leading slash. Regex required for IE8 support
    pathname = $link[0].pathname.replace(/^\//, '')

    Router.history.navigate(pathname, true)
    return