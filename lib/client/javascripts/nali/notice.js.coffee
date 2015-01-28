Nali.Model.extend Notice:

  initialize: ->
    @::::expand Notice: @
    @_addMethods()

  _addMethods: ->
    for name of @_views
      do ( name ) =>
        @[ name ] = ( params ) => @new( @_prepare params ).show name

  _prepare: ( params ) ->
    params = message: params if typeof params is 'string'
    params



Nali.View.extend

  NoticeInfo:
    onShow: -> @hide 3000

  NoticeWarning:
    onShow: -> @hide 3000

  NoticeError:
    onShow: -> @hide 3000
