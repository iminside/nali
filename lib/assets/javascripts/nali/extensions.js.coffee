String::uppercase = ->
  "#{ @toUpperCase() }"

String::lowercase = ->
  "#{ @toLowerCase() }"

String::capitalize = ->
  @charAt(0).uppercase() + @slice(1)
  
String::uncapitalize = ->
  @charAt(0).lowercase() + @slice(1)

String::camelcase = ->
  @replace /(_[^_]+)/g, ( match ) -> match[ 1.. ].capitalize()
  
String::underscore = ->
  str = @replace /([A-Z])/g, ( match ) -> '_' + match.lowercase()
  if str[ 0...1 ] is '_' then str[ 1.. ] else str  
    