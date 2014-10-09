Nali::Application.configure :development do |config|
  
# config.assets_digest = true
  
  config.assets_debug = true
  
# config.assets.js_compressor  = Uglifier.new( mangle: true )
  
# config.assets.css_compressor = YUI::CssCompressor.new
  
  ActiveRecord::Base.logger = false #Logger.new STDOUT 
 
end