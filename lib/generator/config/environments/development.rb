Nali::Application.configure :development do |config|
  
  config.assets_debug = true
  
  ActiveRecord::Base.logger = false #Logger.new STDOUT 
 
end