Nali.extend Controller:

  extension: ->
    if @_name isnt 'Controller'
      @prepareActions() 
      @modelSysname = @_name.replace /s$/, '' 
    @
  
  actions: {}
  
  prepareActions: ->
    @routedActions   = {}
    @preparedActions = {}
    for name, action of @actions when not ( name in [ 'default', 'before', 'after' ] )
      [ name, filters... ] = name.split '/'
      params = []
      for filter in filters[ 0.. ] when /^:/.test filter
        filters.splice filters.indexOf( filter ), 1
        params.push filter[ 1.. ]
      @routedActions[ name ]   = filters: filters, params: params
      @preparedActions[ name ] = [ action ]
    @prepareBefores()
    @prepareAfters()
    @ 
    
  prepareBefores: ->
    if @actions.before?
      beforeActions = {}
      for names, action of @actions.before
        for name in names.split /\s*,\s*/
          ( beforeActions[ name ] ?= [] ).push action
      for name, actions of beforeActions
        @preparedActions[ name ] = actions.concat @preparedActions[ name ]
    @
    
  prepareAfters: ->
    if @actions.after?
      afterActions = {}
      for names, action of @actions.after
        for name in names.split /\s*,\s*/
          ( afterActions[ name ] ?= [] ).push action
      for name, actions of afterActions
        @preparedActions[ name ] = @preparedActions[ name ].concat actions
    @
    
  run: ( action, filters, params ) ->
    controller = @clone 
      collection: @Model.extensions[ @modelSysname ].where filters 
      params:     params
    controller.runAction action
    if controller.defaultPrevented
      controller.collection.destroy()
    else
      controller.collection.show action
      @changeUrl action, filters
    @
    
  runAction: ( name ) ->
    action.call @ for action in @preparedActions[ name ] when not @defaultPrevented
    @
    
  preventDefault: ->
    @defaultPrevented = true
    @ 
      
  redirect: ( args... ) ->
    @Router.go args...
    @preventDefault()
    @
      
  changeUrl: ( action, filters ) ->
    params   = ( value for own key, value of filters )
    url      = @_name.lowercase().replace /s$/, ''
    url     += if action is @actions.default then '' else '/' + action
    url     += '/' + params.join '/' if params.length     
    @Router.setUrl url
    @