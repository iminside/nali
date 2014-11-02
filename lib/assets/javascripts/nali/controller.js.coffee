Nali.extend Controller:

  extension: ->
    if @_name isnt 'Controller'
      @prepareActions() 
      @modelName = @_name.replace /s$/, ''
    @
  
  new: ( collection, filters, params ) ->
    @clone collection: collection, filters: filters, params: params
  
  prepareActions: ->
    @_actions = {}
    for name, action of @actions when not ( name in [ 'default', 'before', 'after' ] )
      [ name, filters... ] = name.split '/'
      params = []
      for filter in filters[ 0.. ] when /^:/.test filter
        filters.splice filters.indexOf( filter ), 1
        params.push filter[ 1.. ]
      @_actions[ name ] = filters: filters, params: params, methods: [ action ]
    @prepareBefores()
    @prepareAfters()
    @ 
    
  prepareBefores: ->
    if @actions?.before?
      list = @analizeFilters 'before'  
      @_actions[ name ].methods = actions.concat @_actions[ name ].methods for name, actions of list
    @
    
  prepareAfters: ->
    if @actions?.after?
      list = @analizeFilters 'after'  
      @_actions[ name ].methods = @_actions[ name ].methods.concat actions for name, actions of list
    @
    
  analizeFilters: ( type ) ->
    list = {}
    for names, action of @actions[ type ]
      [ invert, names ] = switch
        when /^!\s*/.test names then [ true,  names.replace( /^!\s*/, '' ).split /\s*,\s*/ ]
        when names is '*'       then [ true,  [] ]
        else                         [ false, names.split /\s*,\s*/ ]
      for name of @_actions when ( invert and not ( name in names ) ) or ( not invert and name in names )
        ( list[ name ] ?= [] ).push action  
    list
    
  run: ( action, filters, params ) ->
    collection = @Model.extensions[ @modelName ].where filters
    controller = @new( collection, filters, params ).runAction action
    if controller.stopped
      controller.collection.destroy()
    else
      controller.collection.show action
      @Router.setUrl()
    @
    
  runAction: ( name ) ->
    method.call @ for method in @_actions[ name ].methods when not @stopped  
    @
    
  stop: ->
    @stopped = true
    @ 
      
  redirect: ( args... ) ->
    @Router.go args...
    @stop()
    @
