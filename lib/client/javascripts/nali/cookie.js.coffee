Nali.extend Cookie:

  set: ( name, value, options = {} ) ->
    set = "#{ name }=#{ escape( value ) }"
    if options.live? and typeof options.live is 'number'
      date = new Date
      date.setDate date.getDate() + options.live
      date.setMinutes date.getMinutes() - date.getTimezoneOffset()
      set += "; expires=#{ date.toUTCString() }"
    set += '; domain=' + escape options.domain if options.domain?
    set += '; path='   + if options.path? then escape options.path else '/'
    set += '; secure'    if options.secure?
    document.cookie = set
    value

  get: ( name ) ->
    get = document.cookie.match "(^|;) ?#{ name }=([^;]*)(;|$)"
    if get then unescape( get[2] ) else null

  remove: ( name ) ->
    @set name, '', live: -1
