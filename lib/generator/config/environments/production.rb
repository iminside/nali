Nali::Application.configure :production do |config|
  
  ActiveRecord::Base.logger    = false
  
  config.client_digest         = true
  
  config.client.js_compressor  = :uglify

  config.client.css_compressor = :scss
  
end
