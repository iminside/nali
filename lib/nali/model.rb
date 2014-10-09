module Nali

  module Model

    def access_level( client )
      :default
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
      access_action( :read, client ) do |options|
        attributes = { id: self.id }
        options.each do |option| 
          if self.respond_to?( option )
            value = self.send( option )
            if value.is_a?( ActiveRecord::Associations::CollectionProxy )
              relations << value unless self.destroyed?
            elsif value.is_a?( ActiveRecord::Base )
              relations << value unless self.destroyed?
              attributes[ option.to_s + '_id' ] = value.id
            else
              attributes[ option ] = value
            end
          end
        end
        params[ :attributes ] = attributes
        params[ :sysname ]    = self.class.name
        params[ :created ]    = self.created_at.to_f
        params[ :updated ]    = self.updated_at.to_f
        params[ :destroyed ]  = self.destroyed?
      end
      [ params, relations.flatten.compact ]
    end
      
    def clients
      Nali::Clients.clients
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
