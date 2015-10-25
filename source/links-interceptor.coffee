Router.on 'start', ->
  Router.linksInterceptor.start()

Router.on 'stop', ->
  Router.linksInterceptor.stop()

Router.reURIScheme      = /^(\w+):(?:\/\/)?/
Router.reJavaScriptURI  = /^\s*javascript:(.*)$/
Router.reAnchorURI      = /^\s*(#.*)$/

Router.matchURIScheme = (str) ->
  str?.match?(Router.reURIScheme)?[0]

class LinksInterceptor extends BaseClass

  constructor: ->
    super
    _.bindMethod(this, 'intercept', 'onKeyDown', 'onKeyUp')
    @started = false

  start: ->
    if @started
      throw new Error "[#{Router}] Links interceptor has already been started!"

    @$document  = Router.$(document)
    @$window    = Router.$(window)

    @$document.on('click.LinksInterceptor', 'a', @intercept)
    @$window
      .on 'keydown.LinksInterceptor', @onKeyDown
      .on 'keyup.LinksInterceptor',   @onKeyUp
    @started = true
    this

  stop: ->
    unless @started
      throw new Error "[#{Router}] Links interceptor hasn't been started!"

    @$document.off('.LinksInterceptor')
    @$window.off('.LinksInterceptor')
    @started = false
    this

  onKeyDown: ->
    @keyPressed = true

  onKeyUp: ->
    @keyPressed = false

  intercept: (e) ->
    # Only intercept left-clicks
    if e.which isnt 1
      Router.notify 'linksInterceptor:interceptCancel',
                    'Only left-clicks are intercepted.'
      return

    # Allow action "Open in new tab" (CTRL + Left click or Command + Left click)
    if @keyPressed
      Router.notify 'linksInterceptor:interceptCancel',
                    'Links are not intercepted when key is pressed. This allows user to open link in new tab.'
      return

    $link = Router.$(e.currentTarget)

    # Get the href
    # Stop processing if there isn't one
    unless href = $link.attr('href')
      Router.notify 'linksInterceptor:interceptCancel',
                    "Link is missing href attribute or it's value is blank."
      return

    if Router.reJavaScriptURI.test(href)
      Router.notify 'linksInterceptor:interceptCancel',
                    'URI contains javascript: expression.'
      return

    if Router.history.hashChangeBased and Router.reAnchorURI.test(href)
      Router.notify 'linksInterceptor:interceptCancel',
                    'Anchor URIs are not intercepted.'
      return

    # Determine if we're supposed to bypass the link
    # based on it's attributes
    intercept = $link.attr('intercept') ? $link.data('intercept')
    if intercept in ['false', false]
      Router.notify 'linksInterceptor:interceptCancel',
                    "Link interception bypassed based on it's attribute."
      return

    # Return if the URI is absolute, or if URI contains scheme
    if Router.matchURIScheme(href)?
      Router.notify 'linksInterceptor:interceptCancel',
                    'Absolute URI or URI with scheme are not intercepted.'
      return

    # If we haven't been stopped yet, then we prevent the default action
    e.preventDefault()

    route = if Router.history.pushStateBased
      History.derivePath($link[0])
    else
      History.deriveFragment($link[0])

    Router.notify('linksInterceptor:intercept', route)

    Router.navigate(route, true)
    return
