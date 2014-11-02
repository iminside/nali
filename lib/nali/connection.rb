module EventMachine
  module WebSocket
    class Connection
         
      def reset
        @filters = {} 
        @storage = {} 
        @watches = {} 
      end
      
      def filters( model_name )
        @filters ||= {} 
        @filters[ model_name ] ||= []
      end
        
      def filters_add( model_name, new_filter )
        unless( new_filter.keys.include?( :id ) and new_filter.keys.length == 1 )
          exist = false
          filters( model_name ).each { |filter| exist = true if filter.sort.to_s == new_filter.sort.to_s }
          filters( model_name ) << new_filter unless exist
        end
      end
        
      def filter?( model )
        filters( model.class.name.to_sym ).each do |filter|
          result = true
          filter.each { |key, value| result = false if model[ key ] != value }
          return result if result
        end
        false
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
        
      def sync( model )
        params, relations = model.get_sync_params( self )
        if not params.empty? and ( watch_time( model ) < model.updated_at.to_f or model.destroyed? )
          if model.destroyed? then unwatch( model ) else watch_time_up model end
          relations.each { |relation| sync relation }
          send_json action: :sync, params: params 
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
