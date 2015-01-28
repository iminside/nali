module Nali
  
  class Tasks < Rake::TaskLib
    
    def initialize
      @settings = Nali::Application.settings
      define
    end
    
    private

      def define

        namespace :client do
          desc "Compile client files"
          task :compile do
            sprockets_tasks
            remove_cached_files
            remove_compiled_files
            Rake::Task[ 'assets' ].invoke

            compiled_path = File.join @settings.public_folder, 'client'
            Dir[ compiled_path + '/*' ]
            .select { |file| file =~ /.*?\.gz/ }
            .each { |file| File.delete file }
            Dir[ compiled_path + '/*' ]
            .select { |file| file =~ /application.*?\.html/ }
            .each do |file|
              filename    = File.basename( file ).split '.'
              filename[0] = 'index'
              filename    = filename.join '.'
              File.rename file, File.join( @settings.public_folder, filename )
            end
            remove_cached_files
            puts 'Client files compiled'
          end

          desc 'Remove compiled client files'
          task :clean do
            remove_compiled_files
            puts 'Compiled client files removed'
          end

          namespace :cache do
            desc 'Remove cached client files'
            task :clean do
              remove_compiled_files
            end
          end

        end
      end

      def remove_cached_files
        FileUtils.rm_rf File.join( @settings.root, 'tmp/cache' )
      end

      def remove_compiled_files
        FileUtils.rm_rf File.join( @settings.public_folder, 'client' )
        index = File.join( @settings.public_folder, 'index.html' )
        File.delete( index ) if File.exists?( index )
      end

      def sprockets_tasks
        require 'rake/sprocketstask'
        Sprockets::Helpers.configure do |config|
          config.debug     = false
        end
        Rake::SprocketsTask.new do |task|
          task.environment = @settings.client
          task.output      = File.join( @settings.public_folder, 'client' )
          task.assets      = %w( application.html application.js application.css )
        end
      end
    
  end
end
