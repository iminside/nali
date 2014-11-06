module Nali
  
  module Controller
    
    attr_reader :client, :params
    
    def self.included( base )
      base.extend self
      base.class_eval do
        self.class_variable_set :@@befores, []
        self.class_variable_set :@@afters,  []
        def self.befores
          self.class_variable_get :@@befores
        end
        def self.afters
          self.class_variable_get :@@afters
        end
      end
    end
    
    def initialize( client, message )
      @client  = client
      @message = message
      @params  = message[ :params ]
    end
    
    def clients
      Nali::Clients.list
    end
    
    def save
      params[ :id ].to_i.to_s == params[ :id ].to_s ? update : create
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
      client.send_json( { action: 'success', params: params, journal_id: @message[ :journal_id ] } )
    end
    
    def trigger_failure( params = nil )
      client.send_json( { action: 'failure', params: params, journal_id: @message[ :journal_id ] } )
    end
    
    def before( &closure )
      register_before closure: closure, except: [] 
    end
    
    def before_only( *methods, &closure )
      register_before closure: closure, only: methods
    end
    
    def before_except( *methods, &closure )
      register_before closure: closure, except: methods
    end
    
    def after( &closure )
      register_after closure: closure, except: [] 
    end
    
    def after_only( *methods, &closure )
      register_after closure: closure, only: methods
    end
    
    def after_except( *methods, &closure )
      register_after closure: closure, except: methods
    end
    
    def runAction( name )
      self.runFilters name
      self.send( name ) unless @stopped
      self.runFilters name, :after
    end
    
    def stop
      @stopped = true
    end
    
    protected
    
      def runFilters( name, type = :before )
        filters = if type == :before then self.class.befores else self.class.afters end
        filters.each do |obj| 
          if !@stopped and ( ( obj[ :only ] and obj[ :only ].include?( name ) ) or ( obj[ :except ] and !obj[ :except ].include?( name ) ) )
            instance_eval( &obj[ :closure ] )
          end
        end
      end
    
    private 
    
      def register_before( obj )
        befores.push obj
      end

      def register_after( obj )
        afters.push obj
      end

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
