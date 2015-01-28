Nali.extend Connection:

  initialize: ->
    @::expand query: ( args... ) => @query args...
    @

  open: ->
    @_dispatcher           = new WebSocket @Application.wsServer
    @_dispatcher.onopen    = ( event ) => @_identification()
    @_dispatcher.onclose   = ( event ) => @_onClose   event
    @_dispatcher.onerror   = ( event ) => @_onError   event
    @_dispatcher.onmessage = ( event ) => @_onMessage JSON.parse event.data
    @_keepAlive()
    @

  _keepAliveTimer: null
  _journal:        []
  _reconnectDelay: 0

  _onOpen: ->
    @_reconnectDelay = 0
    @trigger 'open'

  _onError: ( event ) ->
    console.warn 'Connection error %O', event

  _onClose: ( event ) ->
    @trigger 'close'
    setTimeout ( => @open() ), @_reconnectDelay * 100
    @_reconnectDelay += 1

  _onMessage: ( message ) ->
    @[ message.action ] message

  _send: ( msg ) ->
    @_dispatcher.send JSON.stringify msg
    @

  _keepAlive: ->
    clearTimeout @_keepAliveTimer if @_keepAliveTimer
    if @Application.keepAliveDelay
      @_keepAliveTimer = setTimeout =>
        @_keepAliveTimer = null
        @_send ping: true
      , @Application.keepAliveDelay * 1000
    @

  _pong: ->
    @_keepAlive()
    @

  _identification: ->
    @_send nali_browser_id: @Cookie.get( 'nali_browser_id' ) or @Cookie.set 'nali_browser_id', @Model.guid()
    @

  _sync: ( message ) ->
    @Model.sync message.params
    @

  _appRun: ( { method, params } ) ->
    @Application[ method ]? params
    @

  _callMethod: ( { model, method, params } ) ->
    if model is 'Notice' then @Notice[ method ] params
    else
      [ model, id ] = model.split '.'
      @Model.callStackAdd model: model, id: id, method: method, params: params
    @

  _success: ( message ) ->
    @_journal[ message.journal_id ].success? message.params
    delete @_journal[ message.journal_id ]
    @

  _failure: ( message ) ->
    @_journal[ message.journal_id ].failure? message.params
    delete @_journal[ message.journal_id ]
    @

  query: ( to, params, success, failure ) ->
    return success?() unless @Application.useWebSockets
    [ controller, action ] = to.split '.'
    @_journal.push callbacks = success: success, failure: failure
    @_send
      controller: controller
      action:     action
      params:     params
      journal_id: @_journal.indexOf callbacks
    @
