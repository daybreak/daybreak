# Uncomment this if you reference any of your controllers in activate
require_dependency 'application_controller'
require 'lib/extend/user'

class RbacBaseExtension < Radiant::Extension
  version "1.2"
  description "Allows other extensions to control access managed by the roles created here. Administrators may add and remove users from roles as needed without regard to the standard Radiant roles."
  url "http://www.saturnflyer.com/"

  define_routes do |map|
    map.namespace :admin do |admin|
      admin.resources :roles#, :member => {:users => :get, :remove_user => :delete, :add_user => :post}
      admin.role_user '/roles/:role_id/users/:id', :controller => 'roles', :action => 'remove_user', :conditions => {:method => :delete}
      admin.role_user '/roles/:role_id/users/:id', :controller => 'roles', :action => 'add_user', :conditions => {:method => :post}
      admin.role_users '/roles/:role_id/users', :controller => 'roles', :action => 'users', :conditions => {:method => :get}
    end
    #legacy paths
    map.rbac 'admin/rbac', :controller => 'admin/roles', :action => 'index'
    map.role_details 'admin/roles/:id', :controller => 'admin/roles', :action => 'show'
  end

  def activate
    Radiant::Config['roles.admin.sees_everything'] = 'true' unless Radiant::Config['roles.admin.sees_everything']
    if Role.table_exists?
      tab 'Settings' do
        add_item 'Roles', '/admin/roles'
      end
      User.send :has_and_belongs_to_many, :roles
      User.send :include, RbacSupport
      User.send :include, RBAC::User
      admin.users.edit[:form].delete('edit_roles')
      UserActionObserver.instance.send :add_observer!, Role
    end
    Admin::UsersController.class_eval {
      helper Admin::AlterationsHelper
    }
  end

  def deactivate
  end

end

