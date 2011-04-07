module PublicAccess
	module LandingPage
	  def index
		  puts "New Landing"
		  redirect_to current_user.landing_page
	  end
	end
end

