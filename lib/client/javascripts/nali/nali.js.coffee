window.Nali =

  _name:      'Nali'
  extensions: {}

  starting: ->
    for name, extension of @extensions
      extension.runExtensions()
      extension.initialize() if extension.hasOwnProperty 'initialize'
      @starting.call extension
    @

  extend: ( params ) ->
    for name, param of params
      param._name          = name
      @[ name ]            = @extensions[ name ] = @child param
      @[ name ].extensions = {}

  clone: ( params = {} ) ->
    obj = @child params
    obj.runCloning()
    obj

  child: ( params ) ->
    obj         = Object.create @
    obj      :: = @
    obj[ name ] = value for name, value of params
    obj.initObservation()
    obj

  expand: ( obj ) ->
    if obj instanceof Object then @[ key ] = value for own key, value of obj
    else console.error "Expand of %O error - argument is not Object", @
    @

  copy: ( obj ) ->
    copy = {}
    copy[ property ] = value for own property, value of obj
    copy

  childOf: ( parent ) ->
    if parent instanceof Object
      return false unless @::?
      return true  if     ( @:: ) is parent
    else
      return false unless @::?._name?
      return true  if     @::_name is parent
    @::childOf parent

  runExtensions: ( context = @ ) ->
    @::?.runExtensions context
    @extension.call context if @hasOwnProperty 'extension'

  runCloning: ( context = @ ) ->
    @::?.runCloning context
    @cloning.call context if @hasOwnProperty 'cloning'

  getter: ( property, callback ) ->
    @__defineGetter__ property, callback
    @

  setter: ( property, callback ) ->
    @__defineSetter__ property, callback
    @

  access: ( obj ) ->
    for own property of obj
      do( property ) =>
        @getter property,           -> obj[ property ]
        @setter property, ( value ) -> obj[ property ] = value
    @

  initObservation: ->
    @observers   = []
    @observables = []
    @

  destroyObservation: ->
    @unsubscribeAll()
    @unsubscribeFromAll()
    @

  addObservationItem: ( to, obj, event, callback ) ->
    return @ for item in @[ to ] when item[0] is obj and item[1] is event and item[2] in [ undefined, callback ]
    @[ to ].push if callback then [ obj, event, callback ] else [ obj, event ]
    @

  removeObservationItem: ( from, obj, event ) ->
    for item in @[ from ][..] when item[0] is obj and ( item[1] is event or not event )
      @[ from ].splice @[ from ].indexOf( item ), 1
    @

  subscribe: ( observer, event, callback ) ->
    @addObservationItem 'observers', observer, event, callback
    observer.addObservationItem 'observables', @, event, callback
    @

  subscribeTo: ( observable, event, callback ) ->
    observable.subscribe @, event, callback
    @

  subscribeOne: ( observer, event, callback ) ->
    callbackOne = ( args... ) =>
      callback.call observer, args...
      @unsubscribe observer, event
    @subscribe observer, event, callbackOne
    @

  subscribeOneTo: ( observable, event, callback ) ->
    observable.subscribeOne @, event, callback
    @

  unsubscribe: ( observer, event ) ->
    @removeObservationItem 'observers', observer, event
    observer.removeObservationItem 'observables', @, event
    @

  unsubscribeFrom: ( observable, event ) ->
    observable.unsubscribe @, event
    @

  unsubscribeAll: ( event ) ->
    @unsubscribe item[0], event for item in @observers[..]
    @

  unsubscribeFromAll: ( event ) ->
    @unsubscribeFrom item[0], event for item in @observables[..]
    @

  trigger: ( event, args... ) ->
    item[2].call item[0], @, args... for item in @observers[..] when item[1] is event
    @
