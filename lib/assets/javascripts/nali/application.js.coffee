Nali.extend Application:
  
  domEngine:     jBone.noConflict()
  wsServer:      'ws://' + window.location.host
  defaultUrl:    ''
  notFoundUrl:   ''
  htmlContainer: 'body'
  title:         'Application'
  
  run: ( options ) ->
    @::starting()
    @[ key ] = value for key, value of options
    document.addEventListener 'DOMContentLoaded', =>
      document.removeEventListener 'DOMContentLoaded', arguments.callee, false 
      @::_           = @domEngine
      @htmlContainer = @_ @htmlContainer
      @setTitle @title
      @trigger 'start'
    , false 
    
  setTitle: ( @title ) ->
    unless @titleBox
      @_( '<title>' ).appendTo 'head' unless @_( 'head title' ).lenght
      @titleBox = @_ 'head title'
    @titleBox.text @title
    @trigger 'update.title'
    @