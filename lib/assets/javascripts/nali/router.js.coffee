Nali.extend Router:

  initialize: ->
    @subscribeTo @Connection, 'open', @start
    @::redirect = ( args... ) => @go args... 
    @    
  
  routes:      {}
    
  start: ->
    @scanRoutes()
    @_( window ).on 'popstate', ( event ) =>
      event.preventDefault()
      event.stopPropagation()
      @saveHistory false
      @go event.target.location.pathname
    @go()
    @

  scanRoutes: ->
    for name, controller of @Controller.extensions when controller.actions?
      route  = '^'
      route += name.lowercase().replace /s$/, ''
      route += '('
      route += Object.keys( controller.routedActions ).join '|' 
      route += ')?'
      @routes[ route ] = controller
    @
    
  go: ( url = window.location.pathname, options = {} ) ->
    url = @prepare( url ) or @prepare( @Application.defaultUrl )
    if found = @findRoute url
      { controller, action, filters, params } = found
      params[ name ] = value for name, value in options
      controller.run action, filters, params
    else if @Application.notFoundUrl
      @go @Application.notFoundUrl
    else console.warn "Not exists route to the address %s", url
    @
  
  prepare: ( url ) ->
    url = url.replace "http://#{ window.location.host }", ''
    url = url[ 1.. ]   or '' if url and url[ 0...1 ] is '/'
    url = url[ ...-1 ] or '' if url and url[ -1.. ]  is '/'
    url
        
  findRoute: ( url ) ->
    for route, controller of @routes when match = url.match new RegExp route, 'i'
      segments = url.split( '/' )[ 1... ]
      if segments[0] in Object.keys( controller.routedActions ) 
        action = segments.shift() 
      else unless action = controller.actions.default 
        console.error 'Unspecified controller action'
      filters = {}
      for name in controller.routedActions[ action ].filters when segments[0]?
        filters[ name ] = segments.shift() 
      params = {}
      for name in controller.routedActions[ action ].params when segments[0]?
        params[ name ] = segments.shift() 
      return controller: controller, action: action, filters: filters, params: params
    false
  
  saveHistory: ( value ) ->
    @saveHistorySwitcher ?= true
    if value in [ true, false ]
      @saveHistorySwitcher = value
      @
    else @saveHistorySwitcher
  
  setUrl: ( url ) ->
    if @saveHistory()
      history.pushState null, null, '/' + ( @url = url ) if url isnt @url 
    else @saveHistory true
    @