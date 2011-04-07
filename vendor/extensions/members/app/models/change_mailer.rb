require 'action_mailer'

class ChangeMailer < ActionMailer::Base
  def change_notice(person)
    @subject    = "#{Radiant::Config['org.name']} - Person record changed"
    @body       = {:person => person}
    @recipients = Radiant::Config['members.person.change_notice_emails'].split(";")
    @from       = Radiant::Config['org.return_email']
    @sent_on    = Time.now
		@content_type = 'text/html'
  end
end

