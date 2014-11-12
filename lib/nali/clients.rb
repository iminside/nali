module Nali
  
  module Clients
    
    def self.list
      @@list ||= []
    end
    
    def clients
      Nali::Clients.list
    end
    
    def on_client_connected( client )
      clients << client
      client_connected( client ) if respond_to?( :client_connected )
    end
    
    def on_received_message( client, message )
      if message[ :ping ]
        client.send_json action: :pong
      else
        name = message[ :controller ].capitalize + 'Controller'
        if Math.const_defined?( name ) and controller = Object.const_get( name )
          controller = controller.new( client, message )
          if controller.respond_to?( action = message[ :action ].to_sym )
            controller.runAction action
          else puts "Action #{ action } not exists in #{ controller }" end
        else puts "Controller #{ name } not exists" end
        on_message( client, message ) if respond_to?( :on_message )
      end
    end
    
    def on_client_disconnected( client )
      clients.delete client
      client_disconnected( client ) if respond_to?( :client_disconnected )
    end
    
  end
  
end
