module Nali
  
  class Tasks < Rake::TaskLib
    
    def initialize
      @settings = Nali::Application.settings
      define
    end
    
    def define
      
      namespace :assets do
        desc "Compile assets" 
        task :compile do
          sprockets_tasks
          
          Rake::Task[ 'assets:clobber' ].invoke
          Rake::Task[ 'assets:cache:clean' ].invoke
          Rake::Task[ 'assets' ].invoke
          
          compiled_assets = File.join @settings.public_folder, 'assets/*'
          Dir[ compiled_assets ]
          .select { |file| file =~ /index.*?\.html/ }
          .each do |file| 
            filename    = File.basename( file ).split '.' 
            filename[0] = 'index'
            filename    = filename.join '.'
            File.rename file, File.join( @settings.public_folder, filename )
          end
          
          puts 'Assets compiled'

        end
        
        desc 'Remove old assets'
        task :clean do
          sprockets_tasks
          Rake::Task[ 'clean_assets' ].invoke
          puts 'Old assets removed'
        end
        
        desc 'Remove all assets'
        task :clobber do
          FileUtils.rm_rf File.join( @settings.public_folder, 'assets' )
          index_path = File.join( @settings.public_folder, 'index.html' )
          File.delete index_path if File.exists? index_path
          File.delete index_path + '.gz' if File.exists? index_path + '.gz'
          puts 'All assets removed'
        end
        
        namespace :cache do
          desc 'Remove cached files'
          task :clean do
            FileUtils.rm_rf File.join( @settings.root, 'tmp/cache' )
            puts 'Cached files removed'
          end
        end

      end
    end
    
    def sprockets_tasks
      require 'rake/sprocketstask'
      Rake::SprocketsTask.new do |task|
        task.environment = @settings.assets
        task.output      = File.join( @settings.public_folder, 'assets' )
        task.assets      = %w( index.html application.js application.css )
      end
    end
    
  end
end
