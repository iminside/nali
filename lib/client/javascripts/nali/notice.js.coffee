Nali.Model.extend Notice:

  initialize: ->
    @::::expand Notice: @

  prepare: ( params ) ->
    params = message: params if typeof params is 'string'
    params

  info: ( params ) ->
    @new( @prepare params ).showInfo()

  warning: ( params ) ->
    @new( @prepare params ).showWarning()

  error:   ( params ) ->
    @new( @prepare params ).showError()


Nali.View.extend

  NoticeInfo:
    onShow: -> @hide 3000

  NoticeWarning:
    onShow: -> @hide 3000

  NoticeError:
    onShow: -> @hide 3000
