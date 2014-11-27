Nali.Model.extend Notice:

  initialize: ->
    @::::expand Notice: @
    @addMethods()

  prepare: ( params ) ->
    params = message: params if typeof params is 'string'
    params

  addMethods: ->
    for name of @views
      do ( name ) =>
        @[ name ] = ( params ) => @new( @prepare params ).show name


Nali.View.extend

  NoticeInfo:
    onShow: -> @hide 3000

  NoticeWarning:
    onShow: -> @hide 3000

  NoticeError:
    onShow: -> @hide 3000
