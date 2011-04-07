module PublicAccess
	module UsersController
		def bounce
			landing = current_user.landing_page rescue "/"
			puts "Bouncing to #{landing}"
			redirect_to landing
		end
	end
end

