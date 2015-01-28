Nali.extend Collection:

  cloning: ->
    @subscribeTo @Model, "create.#{ @model._name.lower() }",  @_onModelCreated
    @subscribeTo @Model, "update.#{ @model._name.lower() }",  @_onModelUpdated
    @subscribeTo @Model, "destroy.#{ @model._name.lower() }", @_onModelDestroyed
    @adaptations = apply: [], cancel: []
    @_ordering   = {}
    @_adaptCollection()
    @refilter()
    @

  _toShowViews:  []
  _visibleViews: []
  length:        0

  refilter: ->
    @model.each ( model ) =>
      if isCorrect = model.isCorrect( @filters ) and not ( model in @ ) then @add model
      else if not isCorrect and model in @ then @remove model
    @

  new: ( model, filters ) ->
    @clone model: model, filters: filters

  _onModelCreated: ( model ) ->
    @add model if not @freezed and model.isCorrect @filters
    @

  _onModelUpdated: ( model ) ->
    if model.written()
      if model in @
        if @freezed or model.isCorrect @filters
          @_reorder()
          @trigger 'update.model', model
        else @remove model
      else if not @freezed and model.isCorrect @filters
        @add model
    @

  _onModelDestroyed: ( model ) ->
    @remove model if model in @ and not @freezed
    @

  _adaptCollection: ->
    for name, method of @model when /^__\w+$/.test( name ) and typeof method is 'function'
      do ( name, method ) =>
        @[ name = name[ 2.. ] ] = ( args... ) =>
          @each ( model ) -> model[ name ] args...
          @
    @

  _adaptModel: ( model, type = 'apply' ) ->
    adaptation.call @, model for adaptation in @adaptations[ type ]
    @

  adaptation: ( apply, cancel ) ->
    @each ( model ) -> apply.call @, model
    @adaptations.apply.push apply
    @adaptations.cancel.unshift cancel if cancel
    @

  add: ( models... ) ->
    for model in [].concat models...
      Array::push.call @, model
      @_adaptModel  model
      @_reorder()
      @trigger 'update.length.add', model
      @trigger 'update.length', 'add', model
    @

  remove: ( model ) ->
    @_adaptModel model, 'cancel'
    Array::splice.call @, @indexOf( model ), 1
    @unsubscribeFrom model
    @_reorder()
    @trigger 'update.length.remove', model
    @trigger 'update.length', 'remove', model
    @

  removeAll: ->
    @each ( model ) -> @remove model
    @length = 0
    @

  each: ( callback ) ->
    callback.call @, model, index for model, index in @
    @

  pluck: ( property ) ->
    model[ property ] for model in @

  indexOf: ( model ) ->
    Array::indexOf.call @, model

  sort: ( sorter ) ->
    Array::sort.call @, sorter
    @

  toArray: ->
    Array::slice.call @, 0

  freeze: ->
    @freezed = true
    @

  unfreeze: ->
    @freezed = false
    @refilter()
    @

  where: ( filters ) ->
    filters[ name ] = value for name, value of @filters
    @model.where filters

  order: ( @_ordering ) ->
    @_reorder()
    @

  _reorder: ->
    if @_ordering.by?
      clearTimeout @_ordering.timer if @_ordering.timer?
      @_ordering.timer = setTimeout =>
        if typeof @_ordering.by is 'function'
          @sort @_ordering.by
        else
          @sort ( one, two ) =>
            one = one[ @_ordering.by ]
            two = two[ @_ordering.by ]
            if @_ordering.as is 'number'
              one = + one
              two = + two
            if @_ordering.as is 'string'
              one = '' + one
              two = '' + two
            ( if one > two then 1 else if one < two then -1 else 0 ) * ( if @_ordering.desc then -1 else 1 )
        @_orderViews()
        delete @_ordering.timer
      , 5
    @

  _orderViews: ->
    if @_inside
      children = Array::slice.call @_inside.children
      children.sort ( one, two ) => @indexOf( one.view.model ) - @indexOf( two.view.model )
      @_inside.appendChild child for child in children
    @

  show: ( viewName, insertTo, isRelation = false ) ->
    @adaptation ( model ) ->
        view = model.view viewName
        if isRelation
          view.subscribeTo @, 'reset', view.hide
        else unless @visible
          @visible = true
          @_prepareViewToShow view
          @_hideVisibleViews()
        else
          @::_visibleViews.push view
        view.show insertTo
        @_inside ?= view.element[0].parentNode
      , ( model ) ->
        model.hide viewName
    @

  hide: ( viewName, delay ) ->
    model.hide viewName, delay for model in @
    @

  _prepareViewToShow: ( view ) ->
    unless view in @::_toShowViews
      @::_toShowViews.push view
      @_prepareViewToShow layout if ( layout = view.layout() )?.childOf? 'View'
    @

  _hideVisibleViews: ->
    view.hide() for view in @::_visibleViews when not( view in @::_toShowViews )
    @::_visibleViews = @::_toShowViews
    @::_toShowViews  = []
    @

  first: ->
    @[0]

  last: ->
    @[ @length - 1 ]

  reset: ->
    @_inside             = null
    @adaptations.length = 0
    @trigger 'reset'
    @

  destroy: ->
    @trigger 'destroy'
    @destroyObservation()
    @removeAll()
    @reset()
    @
