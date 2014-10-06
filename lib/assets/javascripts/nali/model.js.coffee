Nali.extend Model:
  
  extension: ->
    if @sysname isnt 'Model'
      @table       = @tables[ @sysname ] ?= []
      @table.index = {}
      @adapt()
    @
  
  tables:      {}
  hasOne:      []
  hasMany:     []
  attributes:  {}
  updated:     0
  noticesWait: []
    
  adapt: ->
    for name, method of @ when /^_\w+/.test name
      do ( name, method ) =>
        if typeof method is 'function'
          @[ name[ 1.. ] ] = ( args... ) -> @[ name ] args...
    @
    
  notice: ( params ) ->
    @noticesWait.push params
    @runNotices()
    @
    
  runNotices: ->
    for item, index in @noticesWait[ 0.. ]
      if model = @extensions[ item.model ].find item.id
        model[ item.notice ] item.params
        @noticesWait.splice @noticesWait.indexOf( item ), 1
    @
  
  force: ( attributes = {} ) ->
    ( attributes = @copy attributes ).id ?= null
    for name, value of @attributes when not ( name of attributes )
      if value instanceof Object
        attributes[ name ] = if value.default? then value.default else null
      else attributes[ name ] = value or null
    attributes[ name ] = @normalizeValue value for name, value of attributes
    @clone( attributes: attributes ).accessing()
  
  accessing: ->
    @access @attributes
    @setRelations()
    @
  
  save: ( success, failure ) ->
    if @isValid()?
      @query "#{ @sysname.lowercase() }s.save", @attributes, #=> success? @
        ( { attributes, created, updated } ) =>
          @update( attributes, updated, created ).write()
          success? @
    else failure? @
    @
  
  sync: ( { sysname, attributes, created, updated, destroyed } ) ->
    if model = @extensions[ sysname ].find attributes.id 
      if destroyed then model.remove()
      else model.update attributes, updated, created
    else
      model = @extensions[ sysname ].build attributes
      model.updated = updated
      model.created = created
      model.write()
    @
    
  select: ( filters, success, failure ) ->
    @query @sysname.lowercase() + 's.select', filters, success, failure if Object.keys( filters ).length
    
  destroy: ( success, failure ) ->
    @query @sysname.lowercase() + 's.destroy', @attributes, success, failure
             
  write: ->
    unless @ in @table
      @table.push @ 
      @table.index[ @id ] = @
      @onCreate?()
      @Model.trigger "create.#{ @sysname.lowercase() }", @
      @Model.runNotices()
    @
    
  remove: ->
    if @ in @table
      delete @table.index[ @id ]
      @table.splice @table.indexOf( @ ), 1 
      @trigger 'destroy', @
      @onDestroy?()
      @unsubscribeAll()
    @  

  build: ( attributes ) ->
    @force attributes
       
  create: ( attributes, success, failure ) ->
    @build( attributes ).save success, failure
    
  update: ( attributes, updated = 0, created = 0 ) ->
    if not updated or updated > @updated
      @created = created if created
      changed = []
      changed.push name for name, value of attributes when @update_attribute name, value
      if changed.length
        @updated = updated if updated
        @onUpdate? changed
        @trigger 'update', @, changed
    @
    
  update_attribute: ( name, value ) ->
    value = @normalizeValue value
    if @attributes[ name ] isnt value and @isValidAttributeValue( name, value )?
      @attributes[ name ] = value
      @[ 'onUpdate' + name.capitalize() ]?()
      @trigger "update.#{ name }", @
      true
    else false
      
  find: ( id ) ->
    @table.index[ id ]
        
  where: ( filters ) ->
    collection = @Collection.clone model: @, filters: filters
    collection.add model for model in @table when model.isCorrect filters
    if @forced and not collection.length
      attributes = {}
      attributes[ key ] = value for key, value of filters when typeof value in [ 'number', 'string' ]
      collection.add @build attributes
    @select filters
    collection  
    
  normalizeValue: ( value ) ->
    if typeof value is 'string'
      value = "#{ value }".trim()
      if value is ( ( correct = parseInt( value ) ) + '' ) then correct else value
    else value

  isCorrect: ( filters = {} ) ->
    return false unless Object.keys( filters ).length
    return false for name, filter of filters when not @isCorrectAttribute @attributes[ name ], filter
    return true
    
  isCorrectAttribute: ( attribute, filter ) ->                  
    return false unless attribute
    if filter instanceof RegExp
      filter.test attribute
    else if typeof filter is 'string'
      attribute.toString() is filter
    else if typeof filter is 'number'
      parseInt( attribute ) is filter
    else if filter instanceof Array
      attribute.toString() in filter or parseInt( attribute ) in filter
    else false 
    
  setRelations: ->
    @belongsToRelation  attribute for attribute of @attributes when /_id$/.test attribute
    @hasOneRelation     attribute for attribute in [].concat @hasOne
    @hasManyRelation    attribute for attribute in [].concat @hasMany
    @  
    
  belongsToRelation: ( attribute ) ->
    name  = attribute.replace '_id', ''
    model = @Model.extensions[ name.capitalize() ]
    @getter name, => model.find @[ attribute ]
    @ 
  
  hasOneRelation: ( name ) ->
    @getter name, => 
      delete @[ name ]
      ( filters = {} )[ "#{ @sysname.lowercase() }_id" ] = @id
      relation = @Model.extensions[ name.capitalize() ].where filters
      @getter name, => relation.first()
      relation.first()
    @
  
  hasManyRelation: ( name ) ->
    @getter name, => 
      delete @[ name ]
      ( filters = {} )[ "#{ @sysname.lowercase() }_id" ] = @id
      @[ name ] = @Model.extensions[ name[ ...-1 ].capitalize() ].where filters
    @     
  
  view: ( name ) ->
    name = @sysname + name.camelcase().capitalize() unless @View.extensions[ name ]?
    unless ( view = ( @views ?= {} )[ name ] )?
      if ( view = @View.extensions[ name ] )? 
        view = ( ( @views ?= {} )[ name ] = view.clone( model: @ ) )
      else console.error "View %s of model %O does not exist", name, @
    view
          
  show: ( name, insertTo ) ->
    if ( view = @view( name ) )? then view.show insertTo else null 
      
  hide: ( name ) ->
    if ( view = @view( name ) )? then view.hide() else null    
      
  # валидации
  
  validations:          
    # набор валидационных проверок
    presence:  ( value, filter ) -> if filter then value? else not value?
    match:     ( value, filter ) -> not value? or filter.test value
    inclusion: ( value, filter ) -> not value? or value in filter
    exclusion: ( value, filter ) -> not value? or value not in filter
    length:    ( value, filter ) ->
      if not value? then return true else value += ''
      return false if filter.in?  and value.length not in filter.in
      return false if filter.min? and value.length < filter.min
      return false if filter.max? and value.length > filter.max
      return false if filter.is?  and value.length isnt filter.is
      true
    format:    ( value, filter ) -> 
      return true if not value?
      return true if filter is 'boolean' and /^true|false$/.test value
      return true if filter is 'number'  and /^[0-9]+$/.test value
      return true if filter is 'letters' and /^[A-zА-я]+$/.test value
      return true if filter is 'email'   and /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,4})+$/.test value
      false
  
  isValid: ->
    # проверяет валидна ли модель, вызывается перед сохранением модели на сервер если модель валидна, 
    # то вызов model.isValid()? вернет true, иначе false
    return null for name, value of @attributes when not @isValidAttributeValue( name, value )? 
    true
    
  isValidAttributeValue: ( name, value ) ->
    # проверяет валидно ли значение для определенного атрибута модели, вызывается при проверке 
    # валидности модели, а также в методе update() перед изменением значения атрибута, если значение
    # валидно то вызов model.isValidAttributeValue( name, value )? вернет true, иначе false
    for validation, tester of @validations when ( filter = @::attributes[ name ]?[ validation ] )?
      unless tester.call @, value, filter
        console.warn 'Attribute %s of model %O has not validate %s', name, @, validation
        for type in [ 'info', 'warning', 'error' ] when ( message = @::attributes[ name ][ type ] )?
          @Notice[ type ] message: message
        return null 
    true