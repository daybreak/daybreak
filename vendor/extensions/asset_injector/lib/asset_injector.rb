module AssetInjector
  def inject_assets
    unless self.respond_to?(:controller)
      controller = self
    end

    lead = controller.class.to_s.include?('Admin::') ? 'admin/' : ''
    assets = ["#{lead}#{controller.controller_name}", "#{lead}#{controller.controller_name}_#{controller.action_name}", "#{lead}#{controller.controller_name}/#{controller.action_name}"]
    assets.each do |asset|
      include_stylesheet asset
      include_javascript asset
    end

    yield if block_given?

    [@stylesheets, @javascripts]
  end
end

class ApplicationController
  include AssetInjector

  def include_stylesheet(sheet, position = nil)
    if found_stylesheet(sheet) and !@stylesheets.include?(sheet)
      if position
        @stylesheets.insert(position, sheet)
      else
        @stylesheets << sheet
      end
    end
    @content_for_stylesheets = @stylesheets
  end

  #prevent non-existent sheets from being included
  def found_stylesheet(sheet)
    path = "#{RAILS_ROOT}/public/stylesheets/#{sheet}.css"
    File.exist?(path)
  end

  def exclude_stylesheet(sheet)
    @stylesheets.delete(sheet)
    @content_for_stylesheets = @stylesheets
  end

  def include_javascript(script, position = nil)
    if found_javascript(script) and !@javascripts.include?(script)
      if position
        @javascripts.insert(position, script)
      else
        @javascripts << script
      end
    end
    @content_for_javascripts = @javascripts
  end

  #prevent non-existent scripts from being included
  def found_javascript(script)
    path = "#{RAILS_ROOT}/public/javascripts/#{script}.js"
    File.exist?(path)
  end

  def exclude_javascript(script)
    @javascripts.delete(script)
    @content_for_javascripts = @javascripts
  end

end

