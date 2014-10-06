require 'sinatra/base'
require 'sinatra-websocket'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'sprockets'
require 'sprockets-sass'
require 'sprockets-helpers'
require 'coffee-script'
require 'sass'
require 'sqlite3'

module Nali
  
  def self.gem_path
    @gem_path ||= File.expand_path '..', File.dirname( __FILE__ )
  end
  
end

require 'nali/extensions'
require 'nali/application'
require 'nali/connection'
require 'nali/controller'
require 'nali/model'
require 'nali/helpers'