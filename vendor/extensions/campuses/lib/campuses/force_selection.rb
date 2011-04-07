module Campuses
  module ForceSelection
    def self.included(base)
      base.before_filter :confirm_campus_selection
      base.class_eval do
        def self.no_campus_required
          self.skip_before_filter :confirm_campus_selection
        end
      end
    end

    def non_campus_content
      ::CampusesExtension::NON_CAMPUS_URLS.any?{|url| [url, url + '/'].include?(request.path_info)}
    end

    def campus_menu(path = nil)
      path ||= request.path_info
      path = URI.parse(path).path
      [campus_menu_url, campus_menu_url + '/'].include?(path)
    end

    def campus_menu_url
      ::CampusesExtension::MENU
    end

  private
    def confirm_campus_selection
      campus = cookies['campus']
      #TODO: this was disabled.
      #redirect_to campus_menu_url unless campus || non_campus_content || campus_menu
      #redirect_to "/" if campus && campus_menu
    end
  end
end

