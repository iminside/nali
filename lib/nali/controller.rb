module Nali
  
  module Controller
    
    attr_reader :client, :params, :message
    
    def initialize( client, message )
      @client  = client
      @message = message
      @params  = message[ :params ]
    end
    
    def clients
      Nali::Application.clients
    end
    
    def save
      if params[ :id ]
        if model = model_class.find_by_id( params[ :id ] )
          save_success( model ) if model.update_attributes( params )
        end
      else
        if ( model = model_class.new( params ) ).valid?
          save_success( model ) if model.save
        end
      end
    end
    
    def save_success( model )
      on_save( model ) if self.methods.include?( :on_save )
      trigger_success model.get_sync_params( client )
      model.sync client
    end
    
    def select
      model_class.where( params ).each { |model| client.sync model }
      client.filters_add model_name, params
    end

    def destroy
      if model = model_class.find_by_id( params[ :id ] )
        on_destroy( model ) if self.methods.include?( :on_destroy )
        model.destroy() 
        model.sync
      end
    end
    
    def trigger_success( params = nil )
      client.send_json( { action: 'success', params: params, journal_id: message[ :journal_id ] } ) 
    end
    
    def trigger_failure( params = nil )
      client.send_json( { action: 'failure', params: params, journal_id: message[ :journal_id ] } ) 
    end
    
    private 
    
    def model_class
      Object.const_get model_name 
    end

    def model_name
      self.class.name.gsub( 'sController', '' ).to_sym
    end
    
  end

end
