require 'action_mailer'

class EventRequestMailer < ActionMailer::Base
  self.template_root = File.expand_path("#{File.dirname(__FILE__)}/../views/")
  def event_request_notice(event)
    @subject    = "#{event.title} event requested for #{event.start_at.strftime("%m/%d/%Y")}"
    @body       = {:event => event}
    @cc         = event.contact_email if event.contact_email
    @recipients = Radiant::Config['events.event_request_notice_emails'].split(";")
    @from       = Radiant::Config['org.return_email']
    @sent_on    = Time.now
    @content_type = 'text/html'
  end
end

