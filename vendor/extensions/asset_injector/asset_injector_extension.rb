class AssetInjectorExtension < Radiant::Extension
  version "0.1"
  description "Allows stylesheets and javascripts injected into the page"
  url ""

  def activate
    AssetInjector
  end
end

