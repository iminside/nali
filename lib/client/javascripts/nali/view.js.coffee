Nali.extend View:

  extension: ->
    if @_name isnt 'View'
      @_shortName = @_name.underscore().split( '_' )[ 1.. ].join( '_' ).camel()
      @_parseTemplate()
      @_parseEvents()
    @

  cloning: ->
    @my = @model
    @_prepareElement()
    @

  layout: -> null

  _onSourceUpdated:   -> @_draw()

  _onSourceDestroyed: -> @hide()

  getOf: ( source, property ) ->
    @redrawOn source, "update.#{ property }"
    source[ property ]

  getMy: ( property ) ->
    @getOf @model, property

  redrawOn: ( source, event ) ->
    @subscribeTo source, event, @_onSourceUpdated

  insertTo: ->
    if ( layout = @layout() )?.childOf? 'View' then layout.show().yield
    else @Application.htmlContainer

  _draw: ->
    @_runAssistants 'draw'
    @onDraw?()
    @

  show: ( insertTo = @insertTo() ) ->
    unless @visible
      @_runModelCallback 'beforeShow'
      @_draw()._bindEvents()
      @_runAssistants 'show'
      @subscribeTo @model, 'destroy', @_onSourceDestroyed
      @element.appendTo insertTo
      setTimeout ( => @onShow() ), 5 if @onShow?
      @trigger 'show'
      @visible = true
      @_runModelCallback 'afterShow'
    @

  hide: ( delay = 0 ) ->
    if @visible
      @_runModelCallback 'beforeHide'
      @onHide?()
      @_unbindEvents()
      @trigger 'hide'
      @_runAssistants 'hide'
      @_hideElement if delay and typeof( delay ) is 'number' then delay else @hideDelay
      @destroyObservation()
      @visible = false
      @_runModelCallback 'afterHide'
    @

  _hideElement: ( delay ) ->
    if delay then setTimeout ( => @_removeElement() ), delay
    else @_removeElement()
    @

  _removeElement: ->
    @element[0].parentNode.removeChild @element[0]
    @

  _runModelCallback: ( type ) ->
    @model[ type ]?[ @_shortName ]?.call @model
    @

  _runLink: ( event ) ->
    event.preventDefault()
    @_runUrl event.currentTarget.getAttribute 'href'
    @

  _runForm: ( event ) ->
    event.preventDefault()
    @_runUrl event.currentTarget.getAttribute( 'action' ), form2js event.currentTarget, '.', false
    @

  _runUrl: ( url, params ) ->
    if match = url.match /^(@@?)(.+)/
      [ chain, segments... ] = match[2].split '/'
      if result = @_analizeChain chain, ( if match[1].length is 1 then @ else @model )
        [ source, method ] = result
        if method of source
          args = @_parseUrlSegments segments
          args.unshift params if params
          source[ method ] args...
        else console.warn "Method %s not exists of %O", method, source
    else @redirect url, params
    @

  _parseUrlSegments: ( segments ) ->
    params = []
    for segment in segments when segment isnt ''
      [ name, value ] = segment.split ':'
      if value
        last = params[ params.length - 1 ]
        params.push last = {} if typeof last isnt 'object'
        last[ name ] = value
      else params.push name
    params

  _parseEvents: ->
    @_eventsMap = []
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
        if error then error = false else @_eventsMap.push [ selector, type, events, handlers ]
    @

  _bindEvents: ->
    @_bindRoutedElements 'a',    'href',   'click',  ( event ) => @_runLink event
    @_bindRoutedElements 'form', 'action', 'submit', ( event ) => @_runForm event
    for [ selector, type, events, handlers ] in @_eventsMap
      for handler in handlers
        do ( selector, type, events, handler ) =>
          @element[ type ] events, selector, ( event ) => @[ handler ] event
    @

  _bindRoutedElements: ( selector, urlProp, event, callback ) ->
    finded = ( el for el in @element.find( selector ) when el[ urlProp ].indexOf( window.location.origin ) >= 0 )
    finded.push @element[0] if @element.is selector
    ( @_routedElements ?= {} )[ selector ] = @_( finded ).on event, callback
    @

  _unbindEvents: ->
    @element.off()
    @_routedElements.a.off()
    @_routedElements.form.off()
    @

  _prepareElement: ->
    unless @element
      @element         = @_ @template
      @element[0].view = @
      @_addAssistants()
    @

  _getNode: ( path ) ->
    node = @element[0]
    node = node[ sub ] for sub in path
    node

  _parseTemplate: ->
    if container = document.querySelector '#' + @_name.underscore()
      @template = container.innerHTML.trim().replace( /\s+/g, ' ' )
        .replace( /({\s*\+.+?\s*})/g, ' <assist>$1</assist>' )
      unless RegExp( "^<[^>]+" + @_name ).test @template
        @template = "<div class=\"#{ @_name }\">#{ @template }</div>"
      @_parseAssistants()
      container.parentNode.removeChild container
    else console.warn 'Template %s not exists', @_name
    @

  _parseAssistants: ->
    @_assistantsMap = []
    if /{\s*.+?\s*}|bind=".+?"/.test @template
      tmp = document.createElement 'div'
      tmp.innerHTML = @template
      @_scanAssistants tmp.children[0]
    @

  _scanAssistants: ( node, path = [] ) ->
    if node.nodeType is 3
      if /{\s*yield\s*}/.test( node.textContent.trim() ) and node.parentNode.childNodes.length is 1
        @_assistantsMap.push nodepath: path, type: 'Yield'
      else if /^{\s*\w+ of @\w*\s*}$/.test( node.textContent.trim() ) and node.parentNode.childNodes.length is 1
        @_assistantsMap.push nodepath: path, type: 'Relation'
      else if /{\s*.+?\s*}/.test node.textContent
        @_assistantsMap.push nodepath: path, type: 'Text'
    else if node.nodeName is 'ASSIST'
      @_assistantsMap.push nodepath: path, type: 'Html'
    else
      if node.attributes
        for attribute, index in node.attributes
          if attribute.name is 'bind'
            @_assistantsMap.push nodepath: path, type: 'Form'
          else if /{\s*.+?\s*}/.test attribute.value
            @_assistantsMap.push nodepath: path.concat( 'attributes', index ), type: 'Attr'
      @_scanAssistants child, path.concat 'childNodes', index for child, index in node.childNodes
    @

  _addAssistants: ->
    @_assistants = show: [], draw: [], hide: []
    @[ "_add#{ type }Assistant" ] @_getNode nodepath for { nodepath, type } in @_assistantsMap
    @

  _runAssistants: ( type ) ->
    assistant.call @ for assistant in @_assistants[ type ]
    @

  _addTextAssistant: ( node ) ->
    initialValue = node.textContent
    @_assistants[ 'draw' ].push -> node.textContent = @_analize initialValue
    @

  _addAttrAssistant: ( node ) ->
    initialValue = node.value
    @_assistants[ 'draw' ].push -> node.value = @_analize initialValue
    @

  _addHtmlAssistant: ( node ) ->
    parent       = node.parentNode
    initialValue = node.innerHTML
    index        = Array::indexOf.call parent.childNodes, node
    after        = parent.childNodes[ index - 1 ] or null
    before       = parent.childNodes[ index + 1 ] or null
    @_assistants[ 'draw' ].push ->
      start = if after  then Array::indexOf.call( parent.childNodes, after ) + 1 else 0
      end   = if before then Array::indexOf.call parent.childNodes, before  else parent.childNodes.length
      parent.removeChild node for node in Array::slice.call( parent.childNodes, start, end )
      parent.insertBefore element, before for element in @_( @_analize initialValue )
    @

  _addFormAssistant: ( node ) ->
    if bind = @_analizeChain node.attributes.removeNamedItem( 'bind' ).value
      [ source, property ] = bind
      $node = @_ node

      updateSource = ->
        ( params = {} )[ property ] = if node.type is 'checkbox' and !node.checked then null else if node.value is '' then null else node.value
        source.update params
        source.save() unless node.form?

      [ setValue, bindChange ] = switch
        when node.type in [ 'text', 'textarea', 'color', 'date', 'datetime', 'datetime-local', 'email', 'number', 'range', 'search', 'tel', 'time', 'url', 'month', 'week' ]
          [
            -> node.value = source[ property ] or ''
            -> $node.on 'change', => updateSource.call @
          ]
        when node.type in [ 'checkbox', 'radio' ]
          [
            -> node.checked = source[ property ] + '' is node.value
            -> $node.on 'change', => updateSource.call @ if node.type is 'checkbox' or node.checked is true
          ]
        when node.type is 'select-one'
          [
            -> option.selected = true for option in node when source[ property ] + '' is option.value
            -> $node.on 'change', => updateSource.call @
          ]

      @_assistants[ 'show' ].push ->
        setValue.call @
        bindChange.call @
        source.subscribe @, "update.#{ property }", => setValue.call @

      @_assistants[ 'hide' ].push ->
        $node.off 'change'
    @

  _addYieldAssistant: ( node ) ->
    ( @yield = @_ node.parentNode )[0].removeChild node

  _addRelationAssistant: ( node ) ->
    [ match, name, chain ] = node.textContent.match /{\s*(\w+) of @(\w*)\s*}/
    ( insertTo = node.parentNode ).removeChild node
    segments = if chain.length then chain.split '.' else []
    @_assistants[ 'show' ].push ->
      if relation = @_getSource segments
        if relation.childOf 'Collection'
          relation.show name, insertTo, true
          relation.subscribeTo @, 'hide', relation.reset
        else
          view = relation.show name, insertTo
          view.subscribeTo @, 'hide', view.hide

  _analize: ( value ) ->
    value.replace /{\s*(.+?)\s*}/g, ( match, sub ) => @_analizeMatch sub

  _analizeMatch: ( sub ) ->
    if match = sub.match /^@([\w\.]+)(\?)?$/
      if result = @_analizeChain match[1]
        [ source, property ] = result
        source.subscribe? @, "update.#{ property }", @_onSourceUpdated
        if match[2] is '?'
          if source[ property ] then property else ''
        else if source[ property ]? then source[ property ] else ''
      else ''
    else if match = sub.match /^[=|\+](\w+)$/
      @helpers?[ match[1] ]?.call @
    else sub

  _getSource: ( segments, source = @model ) ->
    for segment in segments
      if segment of source then source = source[ segment ]
      else
        console.warn "%s: chain \"%s\" is invalid, segment \"%s\" not exists in %O", @_name, segments.join( '.' ), segment, source
        return null
    source

  _analizeChain: ( chain, source = @model ) ->
    segments = chain.split '.'
    property = segments.pop()
    return null unless source = @_getSource segments, source
    [ source, property ]
