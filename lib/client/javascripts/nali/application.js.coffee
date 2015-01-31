Nali.extend Application:

  domEngine:      jBone.noConflict()
  useWebSockets:  true
  wsServer:       'ws://' + window.location.host
  defaultUrl:     'home'
  notFoundUrl:    'home'
  htmlContainer:  'body'
  title:          'Welcome to Nali'
  keepAliveDelay: 20

  run: ( options ) ->
    @::starting()
    @[ key ] = value for key, value of options
    @_onReadyDOM ->
      @::_           = @domEngine
      @htmlContainer = @_ @htmlContainer
      @setTitle @title
      @Router.start()
      @_runConnection()

  _onReadyDOM: ( callback ) ->
    document.addEventListener 'DOMContentLoaded', =>
      document.removeEventListener 'DOMContentLoaded', arguments.callee, false
      callback.call @
    , false
    @

  _runConnection: ->
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
    @titleBox.html @title
    @trigger 'update.title'
    @










