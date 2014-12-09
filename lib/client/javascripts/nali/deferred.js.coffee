#Nali.extend Deferred:
#
#  new: ( callback ) ->
#    obj         = Object.create @
#    obj.defer   = callback
#    obj.awaits  = []
#    obj.results = []
#    obj
#
#  await: ( callback ) ->
#    wrapper = ( args... ) =>
#      @results.push callback args...
#      @awaits.splice @awaits.indexOf( wrapper ), 1
#      @defer @results unless @awaits.length
#    @awaits.push wrapper
#    wrapper
