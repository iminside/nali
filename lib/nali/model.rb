module Nali

  module Model

    def self.included( base )
      base.extend self
      base.class_eval do
        after_destroy { sync }
      end
    end

    def access_level( client )
      :unknown
    end
    
    def access_action( action, client )
      level = self.access_level client
      if access_levels = access_options[ action ] and access_levels.keys.include?( level )
        options = []
        ( [] << access_levels[ level ] ).flatten.compact.each { |option| options << option.to_sym }
        yield options
      end
    end
    
    def get_sync_params( client )
      params    = {}
      relations = []
      if self.destroyed?
        sync_initial params
        params[ :destroyed ] = true
      else
        access_action( :read, client ) do |options|
          sync_initial params
          options.each do |option|
            if self.respond_to?( option )
              value = self.send option
              if value.is_a?( ActiveRecord::Associations::CollectionProxy )
                relations << value
              elsif value.is_a?( ActiveRecord::Base )
                relations << value
                params[ :attributes ][ option.to_s + '_id' ] = value.id
              else
                params[ :attributes ][ option ] = value
              end
            end
          end
          params[ :created ] = self.created_at.to_f
          params[ :updated ] = self.updated_at.to_f
        end
      end
      [ params, relations.flatten.compact ]
    end

    def sync_initial( params )
      params[ :_name ]      = self.class.name
      params[ :attributes ] = { id: self.id }
    end
      
    def clients
      Nali::Clients.list
    end
    
    def sync( *watches )
      watches.flatten.each { |client| client.watch self }
      clients.each { |client| client.sync self if client.watch?( self ) or client.filter?( self ) }
    end
      
    def notice( name, params )
      clients.each { |client| client.notice self, name, params if client.watch?( self ) }
    end
    
    private
    
    def access_options
      Nali::Application.access_options[ self.class.name.to_sym ] or {}
    end
      
  end

end
