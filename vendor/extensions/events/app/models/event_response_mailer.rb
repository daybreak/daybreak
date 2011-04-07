require 'action_mailer'

class EventResponseMailer < ActionMailer::Base
  self.template_root = File.expand_path("#{File.dirname(__FILE__)}/../views/")
  def event_response_notice(event)
    @subject    = "#{event.title} event requested for #{event.start_at.strftime("%m/%d/%Y")} set to: #{event.event_status}"
    @body       = {:event => event}
    @cc         = event.contact_email if event.contact_email
    @recipients = event.created_by.email if event.created_by
    @from       = Radiant::Config['org.return_email']
    @sent_on    = Time.now
    @content_type = 'text/html'
  end
end

