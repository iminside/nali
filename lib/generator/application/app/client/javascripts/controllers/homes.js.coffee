Nali.Controller.extend Homes:

  actions:
    default: 'index'

    index: ->
      @collection.freeze().add @Model.Home.new()
