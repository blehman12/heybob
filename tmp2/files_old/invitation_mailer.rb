# app/mailers/invitation_mailer.rb
class InvitationMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM_EMAIL', 'events@confab.example.com')

  # Send event invitation to a participant
  def event_invitation(participant)
    @participant = participant
    @event = participant.event
    @user = participant.user
    @venue = @event.venue
    
    # Generate RSVP link with token for easy response
    @rsvp_url = event_rsvp_url(@event, token: @participant.qr_code_token)
    @calendar_export_url = export_event_calendar_url(@event)
    
    mail(
      to: @user.email,
      subject: "You're invited: #{@event.name}"
    ) do |format|
      format.html
      format.text
    end
  end
  
  # Send RSVP confirmation after user responds
  def rsvp_confirmation(participant)
    @participant = participant
    @event = participant.event
    @user = participant.user
    @venue = @event.venue
    
    # Customize message based on response
    subject_text = case @participant.rsvp_status
    when 'yes'
      "You're registered for #{@event.name}"
    when 'maybe'
      "Thanks for your response to #{@event.name}"
    when 'no'
      "Sorry you can't make it to #{@event.name}"
    else
      "RSVP Update for #{@event.name}"
    end
    
    @check_in_url = checkin_url if @participant.yes?
    @calendar_export_url = export_event_calendar_url(@event) if @participant.yes?
    
    mail(
      to: @user.email,
      subject: subject_text
    )
  end
  
  # Send reminder email before event
  def event_reminder(participant)
    @participant = participant
    @event = participant.event
    @user = participant.user
    @venue = @event.venue
    
    # Only send if they confirmed yes
    return unless @participant.yes?
    
    @days_until = ((@event.event_date - Time.current) / 1.day).ceil
    @check_in_url = checkin_url
    @calendar_export_url = export_event_calendar_url(@event)
    
    mail(
      to: @user.email,
      subject: "Reminder: #{@event.name} is #{@days_until == 0 ? 'today' : "in #{@days_until} days"}"
    )
  end
  
  # Send QR code for check-in
  def qr_code_email(participant)
    @participant = participant
    @event = participant.event
    @user = participant.user
    
    # Generate QR code (you might want to use rqrcode gem for this)
    # For now, just include the check-in URL
    @check_in_url = checkin_verify_url(
      token: @participant.qr_code_token,
      event: @event.id,
      participant: @participant.id
    )
    
    mail(
      to: @user.email,
      subject: "Your check-in code for #{@event.name}"
    )
  end
end
