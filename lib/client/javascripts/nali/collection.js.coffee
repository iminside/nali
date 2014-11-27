Nali.extend Collection:

  toShowViews:  []
  visibleViews: []
  length:       0

  cloning: ->
    @subscribeTo @Model, "create.#{ @model._name.lower() }", @onModelCreated
    @subscribeTo @Model, "update.#{ @model._name.lower() }", @onModelUpdated
    @subscribeTo @Model, "destroy.#{ @model._name.lower() }", @onModelDestroyed
    @adaptations = apply: [], cancel: []
    @ordering    = {}
    @adaptCollection()
    @refilter()
    @

  refilter: ->
    @model.each ( model ) => @add model if model.isCorrect( @filters ) and not ( model in @ )
    @

  new: ( model, filters ) ->
    @clone model: model, filters: filters

  onModelCreated: ( model ) ->
    @add model if not @freezed and model.isCorrect @filters
    @

  onModelUpdated: ( model ) ->
    if model.written()
      if model in @
        if @freezed or model.isCorrect @filters
          @reorder()
          @trigger 'update.model', model
        else @remove model
      else if not @freezed and model.isCorrect @filters
        @add model
    @

  onModelDestroyed: ( model ) ->
    @remove model if model in @ and not @freezed
    @

  adaptCollection: ->
    for name, method of @model when /^_\w+$/.test( name ) and typeof method is 'function'
      do ( name, method ) =>
        @[ name = name[ 1.. ] ] = ( args... ) =>
          @each ( model ) -> model[ name ] args...
          @
    @

  adaptModel: ( model, type = 'apply' ) ->
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
      @adaptModel  model
      @reorder()
      @trigger 'update.length.add', model
      @trigger 'update.length', 'add', model
    @

  remove: ( model ) ->
    @adaptModel model, 'cancel'
    Array::splice.call @, @indexOf( model ), 1
    @unsubscribeFrom model
    @reorder()
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

  order: ( @ordering ) ->
    @reorder()
    @

  reorder: ->
    if @ordering.by?
      clearTimeout @ordering.timer if @ordering.timer?
      @ordering.timer = setTimeout =>
        if typeof @ordering.by is 'function'
          @sort @ordering.by
        else
          @sort ( one, two ) =>
            one = one[ @ordering.by ]
            two = two[ @ordering.by ]
            if @ordering.as is 'number'
              one = + one
              two = + two
            if @ordering.as is 'string'
              one = '' + one
              two = '' + two
            ( if one > two then 1 else if one < two then -1 else 0 ) * ( if @ordering.desc then -1 else 1 )
        @orderViews()
        delete @ordering.timer
      , 5
    @

  orderViews: ->
    if @inside
      children = Array::slice.call @inside.children
      children.sort ( one, two ) => @indexOf( one.view.model ) - @indexOf( two.view.model )
      @inside.appendChild child for child in children
    @

  show: ( viewName, insertTo, isRelation = false ) ->
    @adaptation ( model ) ->
        view = model.view viewName
        if isRelation
          view.subscribeTo @, 'reset', view.hide
        else unless @visible
          @visible = true
          @prepareViewToShow view
          @hideVisibleViews()
        else
          @::visibleViews.push view
        view.show insertTo
        @inside ?= view.element[0].parentNode
      , ( model ) ->
        model.hide viewName
    @

  hide: ( viewName, delay ) ->
    model.hide viewName, delay for model in @
    @

  prepareViewToShow: ( view ) ->
    unless view in @::toShowViews
      @::toShowViews.push view
      @prepareViewToShow layout if ( layout = view.layout() )?.childOf? 'View'
    @

  hideVisibleViews: ->
    view.hide() for view in @::visibleViews when not( view in @::toShowViews )
    @::visibleViews = @::toShowViews
    @::toShowViews  = []
    @

  first: ->
    @[0]

  last: ->
    @[ @length - 1 ]

  reset: ->
    @inside             = null
    @adaptations.length = 0
    @trigger 'reset'
    @

  destroy: ->
    @trigger 'destroy'
    @destroyObservation()
    @removeAll()
    @reset()
    @
