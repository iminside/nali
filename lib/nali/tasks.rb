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
          
          assets_folder = File.join @settings.public_folder, 'assets/'
          Dir[ assets_folder + '*' ]
          .select { |file| file =~ /application.*?\.html/ }
          .each do |file| 
            filename    = File.basename( file ).split '.' 
            filename[0] = 'application'
            filename    = filename.join '.'
            File.rename file, assets_folder + filename
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
          FileUtils.rm_rf File.join( @settings.root, 'public/assets' )
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
        task.assets      = %w( application.html application.js application.css )
      end
    end
    
  end
end