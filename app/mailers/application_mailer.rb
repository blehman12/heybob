class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAILER_FROM', 'noreply@crplm.com')
  layout "mailer"
end
