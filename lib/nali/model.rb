module Nali

  module Model
    
    def sync_access( client )
      true
    end
    
    def sync_models( client )
      []
    end
    
    def sync_params( client )
      {}
    end
    
    def get_sync_models( client )
      ( [] << sync_models( client ) ).flatten.compact
    end
    
    def get_sync_params( client )
      attributes        = sync_params( client )
      attributes[ :id ] = self.id
      {
        attributes: attributes,
        created:    self.created_at.to_f,
        updated:    self.updated_at.to_f,
        sysname:    self.class.name,
        destroyed:  self.destroyed?
      }
    end
      
    def clients
      Nali::Application.clients
    end
    
    def sync( *watches )
      watches.flatten.each { |client| client.watch self }
      clients.each { |client| client.sync self if client.watch?( self ) or client.filter?( self ) }
    end
      
    def notice( name, params )
      clients.each { |client| client.notice self, name, params if client.watch?( self ) }
    end
      
  end

end
