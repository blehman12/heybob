# Public Events Controller - No authentication required
class PublicEventsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show, :rsvp, :confirmation, :calendar, :map]
  before_action :find_event, only: [:show, :rsvp, :confirmation, :calendar, :map]
  before_action :check_public_rsvp_enabled, only: [:show, :rsvp]
  before_action :enforce_rsvp_rules, only: [:rsvp]

  def index
    @events = Event.includes(:venue, :categories)
                   .hosted
                   .published
                   .where('event_date >= ?', Date.today)
                   .order(:event_date)

    if params[:tag].present?
      @active_tag = Category.find_by(slug: params[:tag])
      if @active_tag
        @events = @events.joins(:categorizations)
                         .where(categorizations: { category_id: @active_tag.id })
      end
    end
  end

  def show
    @event_participant = EventParticipant.new
    @vendor_events = @event.vendor_events.includes(vendor: [:categories, :hero_image_attachment])
                           .order('vendors.name')

    # If user is logged in, check if they already have an RSVP
    if current_user
      @existing_rsvp = @event.event_participants.find_by(user: current_user)
      @event_participant = @existing_rsvp if @existing_rsvp
    end
  end

  def rsvp
    @event_participant = EventParticipant.new(event_participant_params)
    @event_participant.event = @event

    # Handle user vs guest RSVP
    if current_user
      # Logged-in user RSVP
      @event_participant.user = current_user
      @event_participant.is_guest = false

      # Check if user already has an RSVP and update it instead
      existing_rsvp = @event.event_participants.find_by(user: current_user)
      if existing_rsvp
        if existing_rsvp.update(event_participant_params)
          session[:confirmed_rsvp_ids] ||= []
          session[:confirmed_rsvp_ids] |= [existing_rsvp.id]
          redirect_to public_event_confirmation_path(@event.slug, participant_id: existing_rsvp.id)
        else
          @event_participant = existing_rsvp
          flash.now[:alert] = 'Unable to update RSVP. Please check the form.'
          render :show, status: :unprocessable_entity
        end
        return
      end
    else
      # Guest RSVP
      @event_participant.is_guest = true
      @event_participant.user = nil
    end

    @event_participant.responded_at = Time.current

    if @event_participant.save
      session[:confirmed_rsvp_ids] ||= []
      session[:confirmed_rsvp_ids] |= [@event_participant.id]
      redirect_to public_event_confirmation_path(@event.slug, participant_id: @event_participant.id)
    else
      flash.now[:alert] = 'Unable to save RSVP. Please check the form.'
      render :show, status: :unprocessable_entity
    end
  end

  def confirmation
    @event_participant = @event.event_participants.find_by(id: params[:participant_id])

    unless @event_participant
      redirect_to public_event_path(@event.slug), alert: 'RSVP not found.'
      return
    end

    # Security: verify the viewer is authorized to see this confirmation
    authorized = if @event_participant.is_guest?
      # Guests have no account — verify they submitted this RSVP in this session
      session[:confirmed_rsvp_ids]&.include?(@event_participant.id)
    else
      # Registered users must be viewing their own RSVP
      current_user && @event_participant.user_id == current_user.id
    end

    unless authorized
      redirect_to public_event_path(@event.slug), alert: 'RSVP confirmation not found.'
    end
  end

  def map
    all = @event.vendor_events.includes(:vendor).order('vendors.name')
    @all_vendor_events = all
    @vendor_events = all.select(&:map_positioned?)
  end

  def calendar
    # Generate .ics file for calendar download
    cal = Icalendar::Calendar.new
    
    # Build the event start/end times
    if @event.start_time.present?
      event_start = DateTime.new(
        @event.event_date.year,
        @event.event_date.month,
        @event.event_date.day,
        @event.start_time.hour,
        @event.start_time.min
      )
    else
      event_start = @event.event_date.to_datetime
    end
    
    if @event.end_time.present?
      event_end = DateTime.new(
        @event.event_date.year,
        @event.event_date.month,
        @event.event_date.day,
        @event.end_time.hour,
        @event.end_time.min
      )
    else
      # Default to 2 hours if no end time
      event_end = event_start + 2.hours
    end
    
    cal.event do |e|
      e.dtstart = Icalendar::Values::DateTime.new(event_start)
      e.dtend = Icalendar::Values::DateTime.new(event_end)
      e.summary = @event.name
      e.description = @event.description if @event.description.present?
      
      if @event.venue.present?
        location_parts = [@event.venue.name]
        location_parts << @event.venue.address if @event.venue.address.present?
        e.location = location_parts.join(', ')
      end
      
      e.url = request.base_url + public_event_path(@event.slug)
      e.organizer = "mailto:noreply@confab.local"
      e.uid = "event-#{@event.id}@confab.local"
    end
    
    cal.publish
    
    send_data cal.to_ical, 
              filename: "#{@event.name.parameterize}.ics",
              type: 'text/calendar',
              disposition: 'attachment'
  end

  private

  def find_event
    @event = Event.find_by(slug: params[:slug])

    unless @event
      redirect_to root_path, alert: 'Event not found.'
      return
    end

    unless @event.published?
      redirect_to root_path, alert: 'Event not found.'
    end
  end

  def check_public_rsvp_enabled
    unless @event.public_rsvp_enabled?
      redirect_to root_path, alert: 'This event does not accept public RSVPs.'
    end
  end

  # Server-side enforcement of RSVP business rules (B2 in CODE_REVIEW_BACKLOG.md).
  # The UI hides the form after the deadline / at capacity, but a direct POST
  # to /e/:slug/rsvp must also be rejected — never trust the client.
  def enforce_rsvp_rules
    unless @event.rsvp_open?
      redirect_to public_event_path(@event.slug), alert: 'The RSVP deadline for this event has passed.'
      return
    end

    # Capacity only matters for a new "yes"
    return unless params.dig(:event_participant, :rsvp_status) == 'yes'
    return if @event.spots_remaining.to_i > 0

    # A user who already holds a "yes" may resubmit (e.g. updating answers)
    # without consuming a new spot.
    existing = current_user && @event.event_participants.find_by(user: current_user)
    unless existing&.rsvp_status == 'yes'
      redirect_to public_event_path(@event.slug), alert: 'This event is at capacity.'
    end
  end

  def event_participant_params
    params.require(:event_participant).permit(
      :rsvp_status,
      :guest_name,
      :guest_email,
      :guest_phone,
      :notes,
      rsvp_answers: {}
    )
  end
end
