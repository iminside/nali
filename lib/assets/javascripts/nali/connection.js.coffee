Nali.extend Connection:

  initialize: ->
    @::expand query: ( args... ) => @query args...
    @
    
  open: ->
    @dispatcher = new WebSocket @Application.wsServer
    @dispatcher.onopen    = ( event ) => @onOpen    event
    @dispatcher.onclose   = ( event ) => @onClose   event
    @dispatcher.onerror   = ( event ) => @onError   event
    @dispatcher.onmessage = ( event ) => @onMessage JSON.parse event.data
    @keepAlive()
    @

  keepAliveTimer: null
  journal:        []
    
  onOpen: ( event ) ->
    @trigger 'open'
    
  onError: ( event ) ->
    console.warn 'Connection error %O', event
    
  onClose: ( event ) ->
    @trigger 'close'
    @open()

  onMessage: ( message ) ->
    @[ message.action ] message
  
  send: ( msg ) ->
    @dispatcher.send JSON.stringify msg
    @
      
  keepAlive: ->
    clearTimeout @keepAliveTimer if @keepAliveTimer
    if @Application.keepAliveDelay
      @keepAliveTimer = setTimeout =>
        @keepAliveTimer = null
        @send ping: true
      , @Application.keepAliveDelay * 1000
    @
    
  pong: ->
    @keepAlive()
    @
    
  sync: ( message ) ->
    @Model.sync message.params 
    @
    
  notice: ( { model, notice, params } ) ->
    if model?
      [ model, id ] = model.split '.'
      @Model.notice model: model, id: id, notice: notice, params: params
    else @Notice[ notice ] params 
    @          
  
  success: ( message ) ->
    @journal[ message.journal_id ].success? message.params
    delete @journal[ message.journal_id ] 
    @
    
  failure: ( message ) ->
    @journal[ message.journal_id ].failure? message.params
    delete @journal[ message.journal_id ] 
    @
    
  query: ( to, params, success, failure ) ->
    return success?() unless @Application.useWebSockets
    [ controller, action ] = to.split '.'
    @journal.push callbacks = success: success, failure: failure
    @send 
      controller: controller
      action:     action
      params:     params 
      journal_id: @journal.indexOf callbacks
    @
