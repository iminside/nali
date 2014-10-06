Nali.extend Controller:

  extension: ->
    if @sysname isnt 'Controller'
      @prepareActions() 
      @modelSysname = @sysname.replace /s$/, '' 
    @

  prepareActions: ->
    @routedActions = {}
    if @actions?
      for action of @actions when action isnt 'default'
        [ name, filters... ] = action.split '/'
        params = []
        for filter in filters[ 0.. ] when /^:/.test filter
          filters.splice filters.indexOf( filter ), 1
          params.push filter[ 1.. ]
        @routedActions[ name ] = name: action, filters: filters, params: params
    @
  
  runAction: ( name, filters, params ) ->
    collection = @Model.extensions[ @modelSysname ].where filters 
    result = @actions[ @routedActions[ name ].name ].call @, collection, params
    if result instanceof Object and result.render is false
      collection.destroy()
    else
      collection.show name
      @changeUrl name, filters
    @
      
  redirect: ( args... ) ->
    @::redirect args...
    render: false
    
  query: ( args... ) ->
    @::query args...
    render: false
      
  changeUrl: ( action, filters ) ->
    params   = ( value for own key, value of filters )
    url      = @sysname.lowercase().replace /s$/, ''
    url     += if action is @actions.default then '' else '/' + action
    url     += '/' + params.join '/' if params.length     
    @Router.setUrl url
    @