module Nali

  class Application < Sinatra::Base
   
    set :root,          File.expand_path( '.' )
    set :database_file, File.join( root, 'config/database.yml' )
    set :assets,        Sprockets::Environment.new( root )
    set :assets_digest, false
    set :assets_debug,  false
    set :static,        true
    
    register Sinatra::ActiveRecordExtension
    
    configure :development do
      register Sinatra::Reloader
      also_reload File.join( root, '**/*.rb' )
    end
    
    require File.join( root, 'config/environments', environment.to_s )
    
    configure do
      assets.cache = Sprockets::Cache::FileStore.new File.join( root, 'tmp/cache' )
      
      assets.append_path File.join( Nali.gem_path, 'lib/assets/javascripts' ) 
      
      %w( app/templates app/assets/stylesheets app/assets/javascripts lib/assets/stylesheets 
          lib/assets/javascripts vendor/assets/stylesheets vendor/assets/javascripts
      ).each { |path| assets.append_path File.join( root, path ) }

      Sprockets::Helpers.configure do |config|
        config.environment = assets
        config.debug       = assets_debug
        config.digest      = assets_digest
      end
      
    end

    get '/assets/*.*' do |path, ext|
      pass if ext == 'html' or not asset = settings.assets[ path + '.' + ext ]
      content_type asset.content_type
      params[ :body ] ? asset.body : asset
    end

    get '/*' do
      if !request.websocket?
        settings.assets[ 'application.html' ]
      else
        request.websocket do |client|
          client.onopen    { onopen client }
          client.onmessage { |message| onmessage( client, JSON.parse( message ).keys_to_sym! ) }
          client.onclose   { onclose client }
        end
      end
    end
    
    def onopen( client )
      clients << client
      client_connected client 
    end
    
    def onmessage( client, message )
      if controller = Object.const_get( message[ :controller ].capitalize + 'Controller' )
        controller = controller.new( client, message )
        if controller.methods.include?( action = message[ :action ].to_sym )
          controller.send action
        else puts "Action #{ action } not exists in #{ controller }" end
      else puts "Controller #{ controller } not exists" end
      on_message client, message
    end
    
    def onclose( client )
      clients.delete client
      client_disconnected client
    end
    
    def client_connected( client )
    end
    
    def on_message( client, message )
    end
    
    def client_disconnected( client )
    end
    
    def clients
      self.class.clients
    end
    
    def self.clients
      @@clients ||= []
    end
    
    def self.initialize!
      Dir[ File.join( root, 'lib/*/**/*.rb'    ) ].each { |file| require( file ) }
      Dir[ File.join( root, 'app/*/**/*.rb'    ) ].each { |file| require( file ) }
      Dir[ File.join( root, 'vendor/*/**/*.rb' ) ].each { |file| require( file ) }
      require File.join( root, 'config/application' )
      self
    end
    
    def self.tasks
      initialize!
      require 'sinatra/activerecord/rake'
      require 'rake/sprocketstask'
      Rake::SprocketsTask.new do |task|
        task.environment = settings.assets
        task.output      = File.join( public_folder, 'assets' )
        task.assets      = %w( application.html application.js application.css )
      end
    end
      
  end  

end