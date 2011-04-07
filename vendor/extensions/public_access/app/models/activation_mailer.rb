class ActivationMailer < ActionMailer::Base
	def activation(user)
		@subject    = "Daybreak - Account awaiting activation"
		@body       = {:user => user}
		@recipients = user.email
		@from       = "activation@daybreakweb.com"
		@sent_on    = Time.now
		@content_type = 'text/html'
	end
end
