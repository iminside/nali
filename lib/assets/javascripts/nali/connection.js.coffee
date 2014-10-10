Nali.extend Connection:

  initialize: ->
    @subscribeTo @Application, 'start', @open
    @::query = ( args... ) => @query args... 
    @
    
  open: ->
    @dispatcher = new WebSocket @Application.wsServer
    @dispatcher.onopen    = ( event ) => @onOpen    event
    @dispatcher.onclose   = ( event ) => @onClose   event
    @dispatcher.onmessage = ( event ) => @onMessage JSON.parse event.data
    @keepAlive()
    @
    
  connected:      false
  keepAliveTimer: null
  journal:        []
    
  onOpen: ( event ) ->
    @connected = true
    @trigger 'open'
    
  onMessage: ( message ) ->
    @[ message.action ] message
    
  onClose: ( event ) ->
    @connected = false
    @trigger 'close'
  
  send: ( msg ) ->
    @open() unless @connected
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
    [ controller, action ] = to.split '.'
    @journal.push callbacks = success: success, failure: failure
    @send 
      controller: controller
      action:     action
      params:     params 
      journal_id: @journal.indexOf callbacks
    @