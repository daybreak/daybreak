#TODO: Extract Daybreak specific stuff into a Daybreak extension.
require_dependency 'application_controller'

class PublicAccessExtension < Radiant::Extension
  version "0.2"
  description "Provides public access (signup/signin) to website."
  url ""

  define_routes do |map|
    map.tell        'tell'                 ,:controller => 'users', :action => 'tell'
    map.user_unlock 'users/unlock/:id/:key',:controller => 'users', :action => 'unlock'
    map.user_bounce 'admin/bounce'         ,:controller => 'admin/users', :action => 'bounce'
    map.user_login  'users/:action/:id'    ,:controller => 'users'
    map.welcome     'admin/welcome'        ,:controller => 'admin/users', :action => 'bounce'
    map.welcome     'admin/gc'             ,:controller => 'admin/tasks', :action => 'collect_garbage'
    map.welcome     'admin/monitor_memory' ,:controller => 'admin/tasks', :action => 'monitor_memory'
    map.welcome     'admin/free_megabytes' ,:controller => 'admin/tasks', :action => 'free_megabytes'
  end

  def activate
    Radiant::Config.class_eval do
      #need 'org.root_url'; need 'org.name'; need 'org.return_email'; need 'org.contact_email'
    end
    ApplicationHelper.module_eval do
     	include MarkupHelpers::Toggles
    	include MarkupHelpers::AuthenticityToken
    	include MarkupHelpers::Radiant
    end    
    ApplicationController.class_eval do
      include Memorylogic
      include Styler
      include ShareLayouts::Helper
      include PublicAccess::SetDefaultAssets
      extend  PublicAccess::SetDefaultAssets::ClassMethods
      before_filter :set_default_assets
      before_filter :inject_assets
    end
    Page.instance_eval do
	    def generate_key(len = 12)
		    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
		    key = ""
		    1.upto(len) { |i| key << chars[rand(chars.size-1)] }
		    return key
	    end
    end
    Page.class_eval do #TODO: extract to common area.
			def part!(name)
				part(name) || self.parts.build(:name => name.to_s)
			end
    end
    User.class_eval do
      extend PublicAccess::User::ClassMethods
      include PublicAccess::User
      validates_presence_of :email, :message => 'required' #Required for person linking
      belongs_to :person
    end
    UserActionObserver.observe User, Page, Layout, Snippet, Person, Group, Message, Series #, Photo #TODO better modularize.
    Admin::WelcomeController.class_eval{include PublicAccess::LandingPage}
    Admin::UsersController.class_eval{include PublicAccess::UsersController}
    Admin::PagesController.class_eval{only_allow_access_to :index, :new, :create, :edit, :update, :destroy, :when => [:admin,:staff,:writer,:designer], :denied_url => {:controller => '/admin/users', :action => 'bounce'}}
    Admin::SnippetsController.class_eval{only_allow_access_to :index, :new, :create, :edit, :update, :destroy, :when => [:admin,:designer], :denied_url => {:controller => '/admin/users', :action => 'bounce'}}
  end
end

