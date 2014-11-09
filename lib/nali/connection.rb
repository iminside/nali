module EventMachine
  module WebSocket
    class Connection
         
      def reset
        @storage = {} 
        @watches = {} 
      end

      def []( name )
        @storage ||= {} 
        @storage[ name ] or nil
      end
      
      def []=( name, value = false )
        @storage ||= {} 
        @storage[ name ] = value
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
      end
        
      def sync( *models )
        models.flatten.compact.each do |model|
          params, relations = model.get_sync_params( self )
          if not params.empty? and ( watch_time( model ) < model.updated_at.to_f or model.destroyed? )
            if model.destroyed? then unwatch( model ) else watch_time_up model end
            relations.each { |relation| sync relation }
            send_json action: :sync, params: params
          end
        end
      end
        
      def notice( name, *args )
        message = { action: :notice, notice: name }
        if args[0].is_a?( ActiveRecord::Base )
          model, params     = args
          message[ :model ] = "#{ model.class.name }.#{ model.id }"
        else
          params = args[0]
        end
        message[ :params ] = params
        send_json message
      end
        
      def info( params )
        notice :info, params
      end
        
      def warning( params )
        notice :warning, params
      end
        
      def error( params )
        notice :error, params
      end
        
    end
  end
end
