module Nali
  
  class Generator
    
    def initialize( args )
      if args.first == 'new'
        if args[1] then create_application args[1]
        else puts 'Enter a name for the application' end
      elsif [ 'm', 'model' ].include?( args.first )
        if args[1] then create_model args[1]
        else puts 'Enter a name for the model' end
      elsif [ 'v', 'view' ].include?( args.first )
        if args[1] then create_view args[1]
        else puts 'Enter a name for the view' end
      end  
    end
    
    def create_application( name )
      source = File.join( Nali.path, 'generator/application/.' )
      target = File.join( Dir.pwd, name )
      FileUtils.cp_r source, target
      %w(
        db
        db/migrate
        lib
        lib/client
        lib/client/javascripts
        lib/client/stylesheets
        public
        public/client
        tmp
        vendor
        vendor/client
        vendor/client/javascripts
        vendor/client/stylesheets
        config/initializers
      ).each { |dir| unless Dir.exists?( path = File.join( target, dir ) ) then Dir.mkdir( path ) end }
      puts "Application #{ name } created"
    end

    def render( name, classname )
      require 'erb'
      ERB.new( File.read( File.join( Nali.path, 'generator/templates', "#{ name }.tpl" )  ) ).result binding
    end

    def write( path, content, mode = 'w' )
      File.open( File.join( Dir.pwd, path ), mode ) { |file| file.write( content ) }
      puts ( mode == 'a' ? 'Updated:' : 'Created:' ) + path
    end

    def clean_cache
      FileUtils.rm_rf( File.join( Dir.pwd, "tmp/cache" ) )
    end
        
    def create_model( name )
      if Dir.exists?( File.join( Dir.pwd, 'app' ) )
        if name.scan( '_' ).size > 0
          return puts 'Please don\'t use the underscore'
        end
        clean_cache
        filename  = name.downcase
        classname = name.camelize
        write "app/client/javascripts/models/#{ filename }.js.coffee", render( 'client_model', classname )
        write "app/client/javascripts/controllers/#{ filename }s.js.coffee", render( 'client_controller', classname )
        write "app/server/models/#{ filename }.rb", render( 'server_model', classname )
        write "app/server/controllers/#{ filename }s_controller.rb", render( 'server_controller', classname )
        write "app/server/models/access.yml", render( 'server_model_access', classname ), 'a'
      else puts 'Please go to the application folder' end
    end
        
    def create_view( name )
      if Dir.exists?( File.join( Dir.pwd, 'app' ) )
        dirname, *filename = name.underscore.split( '_' )
        filename  = filename.join( '_' )
        classname = name.underscore.camelize
        if not dirname.empty? and not filename.empty? and not classname.empty?
          clean_cache
          [
            "app/client/javascripts/views/#{ dirname }",
            "app/client/stylesheets/#{ dirname }",
            "app/client/templates/#{ dirname }"
          ].each { |dir| unless Dir.exists?( path = File.join( Dir.pwd, dir ) ) then Dir.mkdir( path ) end }
          write "app/client/javascripts/views/#{ dirname }/#{ filename }.js.coffee", render( 'client_view', classname )
          write "app/client/stylesheets/#{ dirname }/#{ filename }.css.sass", render( 'client_view_styles', classname )
          write "app/client/templates/#{ dirname }/#{ filename }.html", ''
        else puts 'Invalid view name' end
      else puts 'Please go to the application folder' end
    end    
        
  end
  
end
