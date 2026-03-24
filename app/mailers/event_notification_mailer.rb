# app/mailers/event_notification_mailer.rb
class EventNotificationMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM', 'noreply@crplm.com')

  def rsvp_confirmation(participant)
    @participant = participant
    @event = participant.event
    @user = participant.user
    
    mail(
      to: @user.email,
      subject: "RSVP Confirmed: #{@event.name}"
    )
  end
end