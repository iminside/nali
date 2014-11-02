String::upper = ->
  "#{ @toUpperCase() }"

String::lower = ->
  "#{ @toLowerCase() }"

String::capitalize = ->
  @charAt(0).upper() + @slice(1)
  
String::uncapitalize = ->
  @charAt(0).lower() + @slice(1)

String::camel = ->
  @replace /(_[^_]+)/g, ( match ) -> match[ 1.. ].capitalize()
  
String::underscore = ->
  str = @replace /([A-Z])/g, ( match ) -> '_' + match.lower()
  if str[ 0...1 ] is '_' then str[ 1.. ] else str
