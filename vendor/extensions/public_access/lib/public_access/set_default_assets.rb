module PublicAccess
  module SetDefaultAssets
    def backend?
      path_info = request.path_info || '/'
      #puts "path_info = #{path_info}"
      path_info.include?('/admin')
    end

    def custom_extension?
      path_info = request.path_info || '/'
      admin_pages = ['directory','position','group','message','series','event','resource_category','resource', 'recurrence', 'photo']
      admin_pages.detect{ |page| path_info.include?("/admin/#{page}")}
    end

    def set_default_assets
      include_stylesheet 'urban', 0        unless backend? #TODO: 0 is for what?
      include_stylesheet 'urban-leaf', 0   unless backend?
      include_stylesheet 'urban-home', 0   unless backend?
      exclude_stylesheet 'admin/main'      unless backend?
      #include_stylesheet 'form/form'       unless backend?
      include_stylesheet 'admin/form/form' if custom_extension?
      include_stylesheet 'admin/backend'   if custom_extension?

      include_javascript 'jquery-1.4.2'
      include_javascript 'jquery-no-conflicts'
      include_javascript 'scriptaculous'
      include_stylesheet 'calendar_date_select/default'
      include_javascript 'calendar_date_select/calendar_date_select'
      include_javascript 'calendar_date_select/format_american'
    end

    module ClassMethods
      def default_radiant_layout
        self.radiant_layout 'Urban'
      end
    end
  end
end

