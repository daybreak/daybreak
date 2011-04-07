namespace :radiant do
  namespace :extensions do
    namespace :relations do
      desc "Runs the migration of the Relatives extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          RelationsExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          RelationsExtension.migrator.migrate
        end
      end
    end
  end
end

