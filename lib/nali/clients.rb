module Nali
  
  module Clients
    
    def self.clients
      @@clients ||= []
    end
    
    def self.on_client_connected( client )
      clients << client
      client_connected client 
    end
    
    def self.on_received_message( client, message )
      if controller = Object.const_get( message[ :controller ].capitalize + 'Controller' )
        controller = controller.new( client, message )
        if controller.methods.include?( action = message[ :action ].to_sym )
          controller.send action
        else puts "Action #{ action } not exists in #{ controller }" end
      else puts "Controller #{ controller } not exists" end
      on_message client, message
    end
    
    def self.on_client_disconnected( client )
      clients.delete client
      client_disconnected client
    end
    
    def self.client_connected( client )
    end
    
    def self.on_message( client, message )
    end
    
    def self.client_disconnected( client )
    end
    
  end
  
end