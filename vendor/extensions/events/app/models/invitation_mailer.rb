require 'action_mailer'

class InvitationMailer < ActionMailer::Base
  self.template_root = File.expand_path("#{File.dirname(__FILE__)}/../views/")
  
  def invitation(event, sender, recipients, personalized_message)
    @subject    = "Invitation to #{event.title}"
    @body       = {:event => event, :personalized_message => personalized_message}
    @recipients = recipients
    @from       = sender
    @sent_on    = Time.now
    @headers    = {}
  end
end



