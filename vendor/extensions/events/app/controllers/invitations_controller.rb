class InvitationsController < ApplicationController
	default_radiant_layout
	no_login_required

	#before_filter :users_only, :except => [:login, :not_authorized, :logout]
  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => '/'

	def index
		@events = Event.with_invitations
		@content_for_title = 'Invitations'
	end

	def invite
		@event = Event.find(params[:id])
		@content_for_title = 'Invite'
	end

	def deliver
		invitation = params[:invitation]
		@event = Event.find(params[:id])
		@sender     = "#{invitation[:sender_name]} <#{invitation[:sender_email]}>"
		@recipients = params[:invitation][:recipient_email].split(";").collect { |email| email.strip }
		@personalized_message = invitation[:personalized_message]
		if request.post?
			invitation = params[:invitation]
			email = InvitationMailer.create_invitation(@event, @sender, @recipients, @personalized_message)
			email.set_content_type("text/html")
			InvitationMailer.deliver(email)
		end
		@content_for_title = 'Invitation Sent'
	end
end

