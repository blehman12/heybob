# app/mailers/event_notification_mailer.rb
class EventNotificationMailer < ApplicationMailer
  default from: ENV.fetch('GMAIL_USERNAME', 'noreply@example.com')

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