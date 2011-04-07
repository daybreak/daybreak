require_dependency 'application_controller'

class ShareLayoutsExtension < Radiant::Extension
  version "0.2"
  description "Allows Radiant layouts to be used as layouts for standard Rails actions."
  url "http://wiki.radiantcms.org/Thirdparty_Extensions"

  def activate
    ActionController::Base.send :include, ShareLayouts::RadiantLayouts
    ApplicationController.send :helper, ShareLayouts::Helper
 		Page.send :include, ShareLayouts::Tags
  end

  def deactivate
  end

end

