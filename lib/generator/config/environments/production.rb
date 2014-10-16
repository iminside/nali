Nali::Application.configure :production do |config|
  
  ActiveRecord::Base.logger    = false
  
  config.assets_digest         = true
  
  config.assets.js_compressor  = :uglify

  config.assets.css_compressor = :scss
  
end