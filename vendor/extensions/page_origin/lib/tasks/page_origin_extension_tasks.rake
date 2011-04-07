namespace :radiant do
  namespace :extensions do
    namespace :page_origin do
      
      desc "Runs the migration of the Page Origin extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          PageOriginExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          PageOriginExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the Page Origin to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from PageOriginExtension"
        Dir[PageOriginExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(PageOriginExtension.root, '')
          directory = File.dirname(path)
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end
