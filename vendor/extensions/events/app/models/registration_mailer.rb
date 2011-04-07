require 'action_mailer'

class RegistrationMailer < ActionMailer::Base
  self.template_root = File.expand_path("#{File.dirname(__FILE__)}/../views/")
  
  def registration(r)
    @subject    = "Registered for #{r.page.title}"
    @body       = {:registration => r}
    @recipients = r.contact_email
    @from       = "registration@daybreakweb.com"
    @sent_on    = Time.now
    @content_type = 'text/html'
  end
end

