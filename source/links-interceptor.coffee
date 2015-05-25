Router.loadLinksInterceptor = ->
  @linksInterceptor ||= new LinksInterceptor(@linksInterceptorOptions)

class LinksInterceptor

  @include StrictParameters

  reUriScheme: /^(\w+):(?:\/\/)?/

  {bindMethod} = _

  constructor: (options) ->
    @mergeParams(options)
    bindMethod(this, 'intercept')

  start: ->
    Router.$(document).on('click', 'a', @intercept)

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
    return if @reUriScheme.test(href)

    # If we haven't been stopped yet, then we prevent the default action
    e.preventDefault()

    # Get the computed pathname of the link, removing
    # the leading slash. Regex required for IE8 support
    pathname = $link[0].pathname.replace(/^\//, '')

    Router.loadHistory().navigate(pathname, true)