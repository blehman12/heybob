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

  # Notify the host when someone RSVPs (any status). To = per-event override or the creator.
  def host_rsvp_notification(participant)
    @participant = participant
    @event = participant.event
    to = @event.host_notify_email.presence || @event.creator&.email
    return if to.blank?

    mail(
      to: to,
      subject: "New RSVP (#{@participant.rsvp_status_display rescue @participant.rsvp_status}): #{@participant.display_name} — #{@event.name}"
    )
  end
end