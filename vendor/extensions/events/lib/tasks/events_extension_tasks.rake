namespace :radiant do
  namespace :extensions do
    namespace :events do
      desc "Runs the migration of the Events extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          EventsExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          EventsExtension.migrator.migrate
        end
      end
    end
  end
end

