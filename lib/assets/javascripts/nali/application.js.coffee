Nali.extend Application:
  
  domEngine:      jBone.noConflict()
  useWebSockets:  true
  wsServer:       'ws://' + window.location.host
  defaultUrl:     'home'
  notFoundUrl:    'home'
  htmlContainer:  'body'
  title:          'Application'
  keepAliveDelay: 20
  
  run: ( options ) ->
    @::starting()
    @[ key ] = value for key, value of options
    @onReadyDOM ->
      @::_           = @domEngine
      @htmlContainer = @_ @htmlContainer
      @setTitle @title
      @Router.start()
      @runConnection()

  onReadyDOM: ( callback ) ->
    document.addEventListener 'DOMContentLoaded', =>
      document.removeEventListener 'DOMContentLoaded', arguments.callee, false
      callback.call @
    , false
    @

  runConnection: ->
    if @useWebSockets
      @Connection.subscribe @, 'open',  @onConnectionOpen
      @Connection.subscribe @, 'close', @onConnectionClose
      @Connection.subscribe @, 'error', @onConnectionError
      @Connection.open()
    else @redirect()
    @

  onConnectionOpen: ->
    @redirect()

  onConnectionClose: ->

  onConnectionError: ->
    
  setTitle: ( @title ) ->
    @titleBox ?= if ( exists = @_ 'head title' ).lenght then exists else @_( '<title>' ).appendTo 'head'
    @titleBox[0].innerText = @title
    @trigger 'update.title'
    @










