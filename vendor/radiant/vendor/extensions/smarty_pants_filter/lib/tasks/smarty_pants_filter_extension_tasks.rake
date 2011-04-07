namespace :radiant do
  namespace :extensions do
    namespace :smarty_pants_filter do
      
      desc "Runs the migration of the SmartyPants Filter extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          SmartyPantsFilterExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          SmartyPantsFilterExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the SmartyPants Filter to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[SmartyPantsFilterExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(SmartyPantsFilterExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end
