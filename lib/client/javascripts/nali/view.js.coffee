Nali.extend View:

  extension: ->
    if @_name isnt 'View'
      @_shortName = @_name.underscore().split( '_' )[ 1.. ].join( '_' ).camel()
      @parseTemplate()
      @parseEvents()
    @

  cloning: ->
    @my = @model
    @

  layout: -> null

  onSourceUpdated:   -> @draw()

  onSourceDestroyed: -> @hide()

  getOf: ( source, property ) ->
    @redrawOn source, "update.#{ property }"
    source[ property ]

  getMy: ( property ) ->
    @getOf @model, property

  redrawOn: ( source, event ) ->
    @subscribeTo source, event, @onSourceUpdated

  insertTo: ->
    if ( layout = @layout() )?.childOf? 'View' then layout.show().yield
    else @Application.htmlContainer

  draw: ->
    @runAssistants 'draw'
    @onDraw?()
    @

  show: ( insertTo = @insertTo() ) ->
    @prepareElement()
    unless @visible
      @runModelCallback 'beforeShow'
      @draw().bindEvents()
      @runAssistants 'show'
      @subscribeTo @model, 'destroy', @onSourceDestroyed
      @element.appendTo insertTo
      setTimeout ( => @onShow() ), 5 if @onShow?
      @visible = true
      @runModelCallback 'afterShow'
    else
      @draw()
    @

  hide: ( delay = 0 ) ->
    if @visible
      @runModelCallback 'beforeHide'
      @onHide?()
      @trigger 'hide'
      @runAssistants 'hide'
      @hideElement delay or @hideDelay
      @destroyObservation()
      @visible = false
      @runModelCallback 'afterHide'
    @

  hideElement: ( delay ) ->
    if delay and typeof( delay ) is 'number'
      setTimeout ( => @removeElement() ), delay
    else @removeElement()
    @

  removeElement: ->
    @element[0].parentNode.removeChild @element[0]
    @

  runModelCallback: ( type ) ->
    @model[ type ]?[ @_shortName ]?.call @model
    @

  runLink: ( event ) ->
    event.preventDefault()
    @runUrl event.currentTarget.getAttribute 'href'
    @

  runForm: ( event ) ->
    event.preventDefault()
    @runUrl event.currentTarget.getAttribute( 'action' ), form2js event.currentTarget, '.', false
    @

  runUrl: ( url, params ) ->
    if match = url.match /^(@@?)(.+)/
      [ chain, segments... ] = match[2].split '/'
      if result = @analizeChain chain, ( if match[1].length is 1 then @ else @model )
        [ source, method ] = result
        args = @parseUrlSegments segments
        args.unshift params if params
        source[ method ] args...
      else console.warn "Method %s not exists", chain
    else @redirect url, params
    @

  parseUrlSegments: ( segments ) ->
    params = []
    for segment in segments when segment isnt ''
      [ name, value ] = segment.split ':'
      if value
        last = params[ params.length - 1 ]
        params.push last = {} if typeof last isnt 'object'
        last[ name ] = value
      else params.push name
    params

  parseEvents: ->
    @eventsMap = []
    if @events
      @events = [ @events ] if typeof @events is 'string'
      for event in @events
        try
          [ handlers, type, other ] = event.split /\s+(on|one)\s+/
          [ events, selector ]      = other.split /\s+at\s+/
          handlers = handlers.split /\s*,\s*/
          events   = events.replace /\s*,\s*/, ' '
          throw true unless type and events.length and handlers.length
        catch
          console.warn "Events parsing error: \"%s\" of %O", event, @
          error = true
        if error then error = false else @eventsMap.push [ selector, type, events, handlers ]
    @

  bindEvents: ->
    unless @_eventsBinded?
      @element.find( 'a'    ).on 'click',  ( event ) => @runLink event
      @element.find( 'form' ).on 'submit', ( event ) => @runForm event
      @element.on 'click',  ( event ) => @runLink event if @element.is 'a'
      @element.on 'submit', ( event ) => @runForm event if @element.is 'form'
      for [ selector, type, events, handlers ] in @eventsMap
        for handler in handlers
          do ( selector, type, events, handler ) =>
            @element[ type ] events, selector, ( event ) => @[ handler ] event
      @_eventsBinded = true
    @

  prepareElement: ->
    unless @element
      @element         = @_ @template
      @element[0].view = @
      @addAssistants()
    @

  getNode: ( path ) ->
    node = @element[0]
    node = node[ sub ] for sub in path
    node

  parseTemplate: ->
    if container = document.querySelector '#' + @_name.underscore()
      @template = container.innerHTML.trim().replace( /\s+/g, ' ' )
        .replace( /({\s*\+.+?\s*})/g, ' <assist>$1</assist>' )
      unless RegExp( "^<[^>]+" + @_name ).test @template
        @template = "<div class=\"#{ @_name }\">#{ @template }</div>"
      @parseAssistants()
      container.parentNode.removeChild container
    else console.warn 'Template %s not exists', @_name
    @

  parseAssistants: ->
    @assistantsMap = []
    if /{\s*.+?\s*}|bind=".+?"/.test @template
      tmp = document.createElement 'div'
      tmp.innerHTML = @template
      @scanAssistants tmp.children[0]
    @

  scanAssistants: ( node, path = [] ) ->
    if node.nodeType is 3
      if /{\s*yield\s*}/.test( node.textContent.trim() ) and node.parentNode.childNodes.length is 1
        @assistantsMap.push nodepath: path, type: 'Yield'
      else if /^{\s*\w+ of @\w*\s*}$/.test( node.textContent.trim() ) and node.parentNode.childNodes.length is 1
        @assistantsMap.push nodepath: path, type: 'Relation'
      else if /{\s*.+?\s*}/.test node.textContent
        @assistantsMap.push nodepath: path, type: 'Text'
    else if node.nodeName is 'ASSIST'
      @assistantsMap.push nodepath: path, type: 'Html'
    else
      if node.attributes
        for attribute, index in node.attributes
          if attribute.name is 'bind'
            @assistantsMap.push nodepath: path, type: 'Form'
          else if /{\s*.+?\s*}/.test attribute.value
            @assistantsMap.push nodepath: path.concat( 'attributes', index ), type: 'Attr'
      @scanAssistants child, path.concat 'childNodes', index for child, index in node.childNodes
    @

  addAssistants: ->
    @assistants = show: [], draw: [], hide: []
    @[ "add#{ type }Assistant" ] @getNode nodepath for { nodepath, type } in @assistantsMap
    @

  runAssistants: ( type ) ->
    assistant.call @ for assistant in @assistants[ type ]
    @

  addTextAssistant: ( node ) ->
    initialValue = node.textContent
    @assistants[ 'draw' ].push -> node.textContent = @analize initialValue
    @

  addAttrAssistant: ( node ) ->
    initialValue = node.value
    @assistants[ 'draw' ].push -> node.value = @analize initialValue
    @

  addHtmlAssistant: ( node ) ->
    parent       = node.parentNode
    initialValue = node.innerHTML
    index        = Array::indexOf.call parent.childNodes, node
    after        = parent.childNodes[ index - 1 ] or null
    before       = parent.childNodes[ index + 1 ] or null
    @assistants[ 'draw' ].push ->
      start = if after  then Array::indexOf.call( parent.childNodes, after ) + 1 else 0
      end   = if before then Array::indexOf.call parent.childNodes, before  else parent.childNodes.length
      parent.removeChild node for node in Array::slice.call( parent.childNodes, start, end )
      parent.insertBefore element, before for element in @_( @analize initialValue )
    @

  addFormAssistant: ( node ) ->
    if bind = @analizeChain node.attributes.removeNamedItem( 'bind' ).value
      [ source, property ] = bind
      _node = @_ node

      updateSource = ->
        ( params = {} )[ property ] = node.value
        source.update params
        source.save() unless node.form?

      [ setValue, bindChange ] = switch
        when node.type in [ 'text', 'textarea']
          [
            -> node.value = source[ property ]
            -> _node.on 'change', => updateSource.call @
          ]
        when node.type in [ 'checkbox', 'radio' ]
          [
            -> node.checked = source[ property ] + '' is node.value
            -> _node.on 'change', => updateSource.call @ if node.checked is true
          ]
        when node.type is 'select-one'
          [
            -> option.selected = true for option in node when source[ property ] + '' is option.value
            -> _node.on 'change', => updateSource.call @
          ]

      @assistants[ 'show' ].push ->
        setValue.call @
        bindChange.call @
        source.subscribe @, "update.#{ property }", => setValue.call @

      @assistants[ 'hide' ].push ->
        _node.off 'change'
    @

  addYieldAssistant: ( node ) ->
    ( @yield = node.parentNode ).removeChild node

  addRelationAssistant: ( node ) ->
    [ match, name, chain ] = node.textContent.match /{\s*(\w+) of @(\w*)\s*}/
    ( insertTo = node.parentNode ).removeChild node
    segments = if chain.length then chain.split '.' else []
    @assistants[ 'show' ].push ->
      if relation = @getSource segments
        if relation.childOf 'Collection'
          relation.show name, insertTo, true
          relation.subscribeTo @, 'hide', relation.reset
        else
          view = relation.show name, insertTo
          view.subscribeTo @, 'hide', view.hide

  analize: ( value ) ->
    value.replace /{\s*(.+?)\s*}/g, ( match, sub ) => @analizeMatch sub

  analizeMatch: ( sub ) ->
    if match = sub.match /^@([\w\.]+)(\?)?$/
      if result = @analizeChain match[1]
        [ source, property ] = result
        source.subscribe? @, "update.#{ property }", @onSourceUpdated
        if match[2] is '?'
          if source[ property ] then property else ''
        else if source[ property ]? then source[ property ] else ''
      else ''
    else if match = sub.match /^[=|\+](\w+)$/
      @helpers?[ match[1] ]?.call @
    else sub

  getSource: ( segments, source = @model ) ->
    for segment in segments
      if segment of source then source = source[ segment ]
      else
        console.warn "%s: chain \"%s\" is invalid, segment \"%s\" not exists in %O", @_name, segments.join( '.' ), segment, source
        return null
    source

  analizeChain: ( chain, source = @model ) ->
    segments = chain.split '.'
    property = segments.pop()
    return null unless source = @getSource segments, source
    [ source, property ]
