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
      source_path = File.join( Nali.path, 'generator/.' ) 
      target_path = File.join( Dir.pwd, name )
      FileUtils.cp_r source_path, target_path
      dirs = []
      dirs << File.join( target_path, 'app/controllers' )
      dirs << File.join( target_path, 'db' )
      dirs << File.join( target_path, 'db/migrate' )
      dirs << File.join( target_path, 'lib' )
      dirs << File.join( target_path, 'public' )
      dirs << File.join( target_path, 'tmp' )
      dirs << File.join( target_path, 'vendor' )
      dirs << File.join( target_path, 'config/initializers' )
      dirs.each { |path| Dir.mkdir( path ) unless Dir.exists?( path ) }
      puts "Application #{ name } created"
    end
        
    def create_model( name )
      if Dir.exists?( File.join( Dir.pwd, 'app' ) )
        filename  = name.underscore
        classname = name.capitalize_first
        File.open( File.join( Dir.pwd, "app/assets/javascripts/models/#{ filename }.js.coffee" ), 'w' ) do |f|     
          f.write( "Nali.Model.extend #{ classname }: {}" )   
        end
        File.open( File.join( Dir.pwd, "app/assets/javascripts/controllers/#{ filename }s.js.coffee" ), 'w' ) do |f|     
          f.write( "Nali.Controller.extend #{ classname }s: {}" )   
        end
        File.open( File.join( Dir.pwd, "app/models/#{ filename }.rb" ), 'w' ) do |f|     
          f.write( 
"class #{ classname } < ActiveRecord::Base

  include Nali::Model

end" 
            )
        end
        File.open( File.join( Dir.pwd, "app/controllers/#{ filename }s_controller.rb" ), 'w' ) do |f|     
          f.write( 
"class #{ classname }sController
  
  include Nali::Controller
  
end" 
            )
        end
        File.open( File.join( Dir.pwd, "app/models/access.yml" ), 'a' ) do |f|     
          f.write( 
"#{ classname }:
  create:
  read:
  update:
  destroy:


" 
            )
        end
        FileUtils.rm_rf( File.join( Dir.pwd, "tmp/cache" ) )
        puts "Created: app/assets/javascripts/models/#{ filename }.js.coffee"
        puts "Created: app/assets/javascripts/controllers/#{ filename }s.js.coffee"
        puts "Created: app/models/#{ filename }.rb"
        puts "Created: app/controllers/#{ filename }s_controller.rb"
        puts "Updated: app/models/access.yml"
      else puts 'Please go to the application folder' end
    end
        
    def create_view( name )
      if Dir.exists?( File.join( Dir.pwd, 'app' ) )
        dirname, *filename = name.underscore.split( '_' )
        filename  = filename.join( '_' )
        classname = name.capitalize_first
        dirs = []
        dirs << File.join( Dir.pwd, "app/assets/javascripts/views/#{ dirname }" )
        dirs << File.join( Dir.pwd, "app/assets/stylesheets/#{ dirname }" ) 
        dirs << File.join( Dir.pwd, "app/templates/#{ dirname }" ) 
        dirs.each { |path| Dir.mkdir( path ) unless Dir.exists?( path ) }
        File.open( File.join( Dir.pwd, "app/assets/javascripts/views/#{ dirname }/#{ filename }.js.coffee" ), 'w' ) do |f|     
          f.write( "Nali.View.extend #{ classname }: {}" )   
        end 
        File.open( File.join( Dir.pwd, "app/assets/stylesheets/#{ dirname }/#{ filename }.css.sass" ), 'w' ) do |f|     
          f.write( ".#{ classname }" )
        end 
        File.open( File.join( Dir.pwd, "app/templates/#{ dirname }/#{ filename }.html" ), 'w' ) {}
        FileUtils.rm_rf( File.join( Dir.pwd, "tmp/cache" ) )
        puts "Created: app/assets/javascripts/views/#{ dirname }/#{ filename }.js.coffee"
        puts "Created: app/assets/stylesheets/#{ dirname }/#{ filename }.css.sass"
        puts "Created: app/templates/#{ dirname }/#{ filename }.html"
      else puts 'Please go to the application folder' end
    end    
        
  end
  
end