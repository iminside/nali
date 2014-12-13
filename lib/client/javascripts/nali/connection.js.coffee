Nali.extend Connection:

  initialize: ->
    @::expand query: ( args... ) => @query args...
    @

  open: ->
    @dispatcher = new WebSocket @Application.wsServer
    @dispatcher.onopen    = ( event ) => @identification()
    @dispatcher.onclose   = ( event ) => @onClose   event
    @dispatcher.onerror   = ( event ) => @onError   event
    @dispatcher.onmessage = ( event ) => @onMessage JSON.parse event.data
    @keepAlive()
    @

  keepAliveTimer: null
  journal:        []
  reconnectDelay: 0

  onOpen: ->
    @reconnectDelay = 0
    @trigger 'open'

  onError: ( event ) ->
    console.warn 'Connection error %O', event

  onClose: ( event ) ->
    @trigger 'close'
    setTimeout ( => @open() ), @reconnectDelay * 100
    @reconnectDelay += 1

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

  identification: ->
    @send nali_browser_id: @Cookie.get( 'nali_browser_id' ) or @Cookie.set 'nali_browser_id', @Model.guid()
    @

  sync: ( message ) ->
    @Model.sync message.params
    @

  appRun: ( { method, params } ) ->
    @Application[ method ]? params
    @

  callMethod: ( { model, method, params } ) ->
    if model is 'Notice' then @Notice[ method ] params
    else
      [ model, id ] = model.split '.'
      @Model.callStackAdd model: model, id: id, method: method, params: params
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
