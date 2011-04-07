namespace :radiant do
  namespace :extensions do
    namespace :configuration do
      
      desc "Runs the migration of the Configuration extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          ConfigurationExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          ConfigurationExtension.migrator.migrate
        end
      end
    
    end
  end
end