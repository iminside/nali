module Nali

  class Application < Sinatra::Base
   
    set :root,          File.expand_path( '.' )
    set :database_file, File.join( root, 'config/database.yml' )
    set :client,        Sprockets::Environment.new( root )
    set :client_digest, false
    set :client_debug,  false
    set :static,        true
    
    register Sinatra::ActiveRecordExtension
    
    configure :development do
      register Sinatra::Reloader
      also_reload File.join( root, '**/*.rb' )
    end
    
    require File.join( root, 'config/environments', environment.to_s )
    
    configure do
      
      client.cache = Sprockets::Cache::FileStore.new File.join( root, 'tmp/cache' )
      
      client.append_path File.join( Nali.path, 'client/javascripts' )

      %w( app/client/templates app/client/stylesheets app/client/javascripts lib/client/stylesheets
          lib/client/javascripts vendor/client/stylesheets vendor/client/javascripts
      ).each { |path| client.append_path File.join( root, path ) }

      Sprockets::Helpers.configure do |config|
        config.environment = client
        config.debug       = client_debug
        config.digest      = client_digest
        config.prefix      = '/client'
      end
      
    end

    get '/client/*.*' do |path, ext|
      pass if ext == 'html' or not asset = settings.client[ path + '.' + ext ]
      content_type asset.content_type
      params[ :body ] ? asset.body : asset
    end
    
    require File.join( root, 'app/server/routes' )
    
    include Nali::Clients

    get '/*' do
      if !request.websocket?
        compiled_path = File.join settings.public_folder, 'index.html'
        if settings.environment != :development and File.exists?( compiled_path )
          send_file compiled_path
        else
          settings.client[ 'application.html' ]
        end
      else
        request.websocket do |client|
          client.onopen    { on_client_connected client }
          client.onmessage { |message| on_received_message( client, JSON.parse( message ).keys_to_sym! ) }
          client.onclose   { on_client_disconnected client }
        end
      end
    end
    
    def self.access_options
      settings.environment == :development ? get_access_options : @access_options ||= get_access_options
    end
    
    def self.initialize!
      %w(
        lib/*/**/*.rb
        app/server/controllers/application_controller.rb
        app/server/**/*.rb
        config/application
        app/server/clients
        config/initializers/**/*.rb
      ).each { |path| Dir[ File.join( root, path ) ].each { |file| require( file ) } }
      self
    end
    
    def self.tasks
      initialize!
      require 'rake/tasklib'
      require 'sinatra/activerecord/rake'
      require 'nali/tasks'
      Nali::Tasks.new 
    end

    private

      def self.get_access_options
        YAML.load_file( File.join( root, 'app/server/models/access.yml' ) ).keys_to_sym!.each_value do |sections|
          [ :create, :read, :update ].each do |type|
            if section = sections[ type ]
              section.each_key { |level| parse_access_level section, level }
            end
          end
        end
      end

      def self.parse_access_level( section, level )
        parsed = []
        if section[ level ]
          section[ level ].each do |value|
            value =~ /^\+/ ? parsed += parse_access_level( section, value[ /[^\+]+/ ].to_sym ) : parsed << value
          end
        end
        section[ level ] = parsed
      end
      
  end  

end
