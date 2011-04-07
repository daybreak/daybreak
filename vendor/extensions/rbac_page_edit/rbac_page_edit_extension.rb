# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class RbacPageEditExtension < Radiant::Extension
  version "1.0"
  description "Restricts user access of pages based upon role. Based upon the RBAC Base extension."
  url "http://saturnflyer.com/"

  class MissingRequirement < StandardError; end

  def activate
    raise RbacPageEditExtension::MissingRequirement.new('RbacBaseExtension must be installed and loaded first.') unless defined?(RbacBaseExtension)

    Page.class_eval {
      belongs_to :role
    }
    Role.class_eval {
      if Page.column_names.include?('role_id') # done to allow migrating down rbac_base while this extension still exists
        has_many :pages, :dependent => :nullify
      end
    }
    Admin::PagesController.send :include, PagesControllerRoleExtensions
    admin.pages.index.add :node, "page_role_td", :before => "status_column"
    admin.pages.index.add :sitemap_head, "page_role_th", :before => "status_column_header"
    admin.pages.edit.add :parts_bottom, "page_role", :before => "edit_layout_and_type"
  end

  def deactivate
    # admin.tabs.remove "Rbac Page Edit"
  end

end

