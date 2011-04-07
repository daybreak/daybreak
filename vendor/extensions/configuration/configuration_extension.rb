# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class ConfigurationExtension < Radiant::Extension
  version "1.0"
  description "Displays the configuration settings for updating"
  url ""

  define_routes do |map|
    map.connect 'admin/configuration/:action', :controller => 'admin/configuration'
  end

  def activate
    tab "Settings" do
      add_item "Config", "/admin/configuration"
    end
  end
end

