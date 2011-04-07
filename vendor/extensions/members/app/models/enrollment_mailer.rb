require 'action_mailer'

class EnrollmentMailer < ActionMailer::Base
  def enrollment_notice(person, group)
    @subject    = "#{person.full_name} joined the #{group.name} group"
    @body       = {:person => person, :group => group}
    @recipients = group.enrollment_notice_emails
    @from       = Radiant::Config['org.return_email']
    @sent_on    = Time.now
    @content_type = 'text/html'
  end
end

