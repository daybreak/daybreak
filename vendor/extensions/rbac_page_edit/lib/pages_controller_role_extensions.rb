module PagesControllerRoleExtensions
  def self.included(base)
    base.class_eval {
      only_allow_access_to :new, :edit, :destroy,
        :if => :user_is_in_page_role,
        :denied_url => :back,
        :denied_message => "You lack the necessary role to manipulate this page."

      def user_is_in_page_role
        return true if current_user.admin? || current_user.developer?

        page = Page.find(params[:id] || params[:page_id] || params[:parent_id])
        page_ancestry = []
        
        until page.nil? do
          page_ancestry << page
          return true if page.role && current_user.send("#{page.role.role_name.underscore}?")
          page = page.parent
        end
        
        locked_pages = page_ancestry.select{|p|p.role}

        return locked_pages.length == 0
      end

      before_filter :disallow_role_change
      def disallow_role_change
        if params[:page] && !current_user.admin?
          params[:page].delete('role_id')
        end
      end
    }
  end
end

