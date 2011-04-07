#TODO: see if this can be accomplished by overriding routes
#m = Mapper()
#m.connect('login','users/login', :controller => 'user')

#ActionController::Routing::Routes.draw do |map|
#  map.with_options(:controller => 'users') do |welcome|
#    welcome.login 'user/login',                        :action => 'login'
#  end
#end

#TODO: can this be uncommented?  it was when using 0.6.4
#module LoginSystem
#protected
#	def authenticate
#		action = params['action'].to_s.intern
#		if !login_required? or (current_user and user_has_access_to_action?(action))
#			true
#		else
#			if current_user
#				permissions = self.class.controller_permissions[self.class][action]
#				flash[:error] = permissions[:denied_message] || 'Access denied.'
#				redirect_to permissions[:denied_url] || { :action => :index }
#			else
#				redirect_to user_login_url #changed from login_url
#			end
#			false
#		end
#	end
#end

