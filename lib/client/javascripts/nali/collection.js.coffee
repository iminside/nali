Nali.extend Collection:

  toShowViews:  []
  visibleViews: []
  length:       0

  cloning: ->
    @subscribeTo @Model, "create.#{ @model._name.lower() }", @onModelCreated
    @adaptations = []
    @ordering    = {}
    @adaptCollection()
    @

  new: ( model, filters ) ->
    @clone model: model, filters: filters

  onModelCreated: ( extModel, model ) ->
    @add model if model.isCorrect @filters
    @

  onModelUpdated: ( model ) ->
    if model.isCorrect @filters
      @reorder()
      @trigger 'update.model', model
    else @remove model
    @

  onModelDestroyed: ( model ) ->
    @remove model
    @

  adaptCollection: ->
    for name, method of @model when /^_\w+$/.test( name ) and typeof method is 'function'
      do ( name, method ) =>
        @[ name = name[ 1.. ] ] = ( args... ) =>
          @adaptation ( model ) -> model[ name ] args...
          @
    @

  adaptModel: ( model ) ->
    adaptation.call @, model for adaptation in @adaptations
    @

  adaptation: ( callback ) ->
    callback.call @, model for model in @
    @adaptations.push callback
    @

  add: ( model ) ->
    Array::push.call @, model
    @adaptModel  model
    @subscribeTo model, 'destroy', @onModelDestroyed
    @subscribeTo model, 'update',  @onModelUpdated
    @reorder()
    @trigger 'update.length.add', model
    @trigger 'update.length', 'add', model
    @

  indexOf: ( model ) ->
    Array::indexOf.call @, model

  remove: ( model ) ->
    Array::splice.call @, @indexOf( model ), 1
    @unsubscribeFrom model
    @reorder()
    @trigger 'update.length.remove', model
    @trigger 'update.length', 'remove', model
    @

  removeAll: ->
    delete @[ index ] for model, index in @
    @length = 0
    @

  sort: ( sorter ) ->
    Array::sort.call @, sorter
    @

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
