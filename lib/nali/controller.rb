module Nali
  
  module Controller
    
    attr_reader :client, :params, :message
    
    def initialize( client, message )
      @client  = client
      @message = message
      @params  = message[ :params ]
    end
    
    def clients
      Nali::Clients.clients
    end
    
    def save
      params[ :id ] ? update : create
    end
    
    def create
      model = model_class.new params 
      model.access_action( :create, client ) do |options|
        permit_params options
        if ( model = model_class.new( params ) ).save
          trigger_success model.get_sync_params( client )[0]
          model.sync client
        else trigger_failure end
      end
    end
    
    def update
      if model = model_class.find_by_id( params[ :id ] )
        model.access_action( :update, client ) do |options|
          permit_params options
          if model.update( params )
            trigger_success model.get_sync_params( client )[0] 
            model.sync client
          else trigger_failure end
        end
      end
    end
    
    def select
      model_class.where( params ).each { |model| client.sync model }
      client.filters_add model_name, params
    end

    def destroy
      if model = model_class.find_by_id( params[ :id ] )
        model.access_action( :destroy, client ) do |options|
          model.destroy()
          trigger_success model.id 
          model.sync
        end
      else trigger_failure end
    end
    
    def trigger_success( params = nil )
      client.send_json( { action: 'success', params: params, journal_id: message[ :journal_id ] } ) 
    end
    
    def trigger_failure( params = nil )
      client.send_json( { action: 'failure', params: params, journal_id: message[ :journal_id ] } ) 
    end
    
    private 
    
    def permit_params( filter )
      params.keys.each { |key| params.delete( key ) unless filter.include?( key ) }
      params
    end
    
    def model_class
      Object.const_get model_name 
    end

    def model_name
      self.class.name.gsub( 'sController', '' ).to_sym
    end
    
  end

end
