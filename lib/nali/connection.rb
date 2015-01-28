module EventMachine
  module WebSocket
    class Connection
         
      attr_accessor :browser_id

      def all_tabs
        Nali::Clients.list
          .select { |client| client.browser_id == self.browser_id }
          .each{ |client| yield( client ) if block_given? }
      end

      def other_tabs
        Nali::Clients.list
          .select { |client| client != self and client.browser_id == self.browser_id }
          .each{ |client| yield( client ) if block_given? }
      end

      def reset
        @storage = {} 
        @watches = {} 
        self
      end

      def storage
        @storage ||= {} 
      end

      def []( name = nil )
        name ? ( storage[ name ] or nil ) : storage
      end
      
      def []=( name, value )
        storage[ name ] = value
      end
        
      def watches
        @watches ||= {} 
      end
      
      def watch( model )
        watches[ model.class.name + model.id.to_s ] ||= 0
      end

      def unwatch( model )
        watches.delete model.class.name + model.id.to_s
      end
        
      def watch?( model )
        if watches[ model.class.name + model.id.to_s ] then true else false end
      end
         
      def watch_time( model )
        watches[ model.class.name + model.id.to_s ] or 0
      end
        
      def watch_time_up( model )
        watches[ model.class.name + model.id.to_s ] = model.updated_at.to_f
      end
        
      def send_json( hash )
        send hash.to_json
        self
      end
        
      def sync( *models )
        models.flatten.compact.each do |model|
          if watch_time( model ) < model.updated_at.to_f or model.destroyed?
            params, relations = model.get_sync_params( self )
            unless params.empty?
              if model.destroyed? then unwatch( model ) else watch_time_up model end
              relations.each { |relation| sync relation }
              send_json action: :_sync, params: params
            end
          end
        end
        self
      end
        
      def call_method( method, model, params = nil )
        model = "#{ model.class.name }.#{ model.id }" if model.is_a?( ActiveRecord::Base )
        send_json action: :_callMethod, model: model, method: method, params: params
        self
      end

      def notice( method, params = nil )
        call_method method, :Notice, params
        self
      end
        
      def info( params )
        notice :info, params
        self
      end
        
      def warning( params )
        notice :warning, params
        self
      end
        
      def error( params )
        notice :error, params
        self
      end

      def app_run( method, params = nil )
        send_json action: :_appRun, method: method, params: params
        self
      end
        
    end
  end
end
