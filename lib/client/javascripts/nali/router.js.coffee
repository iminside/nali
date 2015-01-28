Nali.extend Router:

  initialize: ->
    @::expand redirect: ( args... ) => @redirect args...
    @

  _routes: {}

  start: ->
    @_scanRoutes()
    @_( window ).on 'popstate', ( event ) =>
      event.preventDefault()
      event.stopPropagation()
      @_saveHistory = false
      @redirect event.target.location.pathname
    @

  _scanRoutes: ->
    for name, controller of @Controller.extensions when controller.actions?
      route  = '^'
      route += name.lower().replace /s$/, 's*(\/|$)'
      route += '('
      route += Object.keys( controller._actions ).join '|'
      route += ')?'
      @_routes[ route ] = controller
    @

  redirect: ( url = window.location.pathname, options = {} ) ->
    if found = @_findRoute @_prepare( url ) or @_prepare( @Application.defaultUrl )
      { controller, action, filters, params } = found
      params[ name ] = value for name, value in options
      controller.run action, filters, params
    else if @Application.notFoundUrl
      @redirect @Application.notFoundUrl
    else console.warn "Not exists route to the address %s", url
    @

  _prepare: ( url ) ->
    url = url.replace "http://#{ window.location.host }", ''
    url = url[ 1.. ]   or '' if url and url[ 0...1 ] is '/'
    url = url[ ...-1 ] or '' if url and url[ -1.. ]  is '/'
    url

  _findRoute: ( url ) ->
    for route, controller of @_routes when match = url.match new RegExp route, 'i'
      segments = ( @routedUrl = url ).split( '/' )[ 1... ]
      if segments[0] in Object.keys( controller._actions )
        action = segments.shift()
      else unless action = controller.actions.default
        console.error 'Unspecified controller action'
      filters = {}
      for name in controller._actions[ action ].filters when segments[0]?
        filters[ name ] = segments.shift()
      params = {}
      for name in controller._actions[ action ].params
        params[ name ] = if segments[0]? then segments.shift() else null
      return controller: controller, action: action, filters: filters, params: params
    false

  changeUrl: ( url = null ) ->
    if @_saveHistory
      @routedUrl = url if url?
      history.pushState null, null, '/' + ( @url = @routedUrl ) if @routedUrl isnt @url
    else @_saveHistory = true
    @
