# app/controllers/admin/events_controller.rb
require 'csv'

class Admin::EventsController < Admin::BaseController
  before_action :set_event, only: [:show, :edit, :update, :destroy, :update_status, :participants, :add_participant, :export_participants, :bulk_invite, :cockpit, :qr_code]
  before_action :load_venues, only: [:new, :create, :edit, :update]
  before_action :load_users, only: [:new, :create, :edit, :update]

  def index
    @status_counts = Event.group(:lifecycle_status).count
    @events = Event.includes(:venue, :creator, event_participants: :user)
                   .order(:event_date)
    @events = @events.where(lifecycle_status: params[:lifecycle_status]) if params[:lifecycle_status].present?
    @events = @events.page(params[:page]).per(20)
  end

  def show
    @participants = @event.event_participants.includes(:user)
    
    # Split participants by role for the view
    @organizers = @participants.where(role: 'organizer')
    @vendors = @participants.where(role: 'vendor') 
    @attendees = @participants.where(role: 'attendee')
    
    # FIXED: Query event_participants directly instead of joining to users
    @stats = {
      total_participants: @participants.count,
      yes_responses: @participants.where(rsvp_status: :yes).count,
      no_responses: @participants.where(rsvp_status: :no).count,
      maybe_responses: @participants.where(rsvp_status: :maybe).count,
      pending_responses: @participants.where(rsvp_status: :pending).count,
      checked_in: @participants.checked_in.count  # Use the scope
    }
  end

  def new
    @event = Event.new
    @defaults_source = apply_event_defaults(@event)
  end

  def create
    @event = Event.new(event_params)
    @event.creator = current_user

    if @event.save
      redirect_to admin_event_path(@event), notice: 'Event created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @event set by before_action
    # @venues and @users loaded by before_action
  end

  def update
    if @event.update(event_params)
      redirect_to admin_event_path(@event), notice: 'Event updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to admin_events_path, notice: 'Event deleted successfully.'
  end

  def update_status
    @event = Event.find(params[:id])
    if @event.update(lifecycle_status: params[:lifecycle_status])
      redirect_to admin_event_path(@event), notice: "Event status updated to #{@event.lifecycle_status.humanize}."
    else
      redirect_to admin_event_path(@event), alert: "Could not update status."
    end
  end

  def participants
    @participants = @event.event_participants.includes(:user)
    
    # FIXED: Use event_participants.rsvp_status instead of users.rsvp_status
    @participant_counts = {
      total: @participants.count,
      yes: @participants.where(rsvp_status: :yes).count,
      no: @participants.where(rsvp_status: :no).count,
      maybe: @participants.where(rsvp_status: :maybe).count,
      pending: @participants.where(rsvp_status: :pending).count
    }
    
    # Provide users for the dropdown (exclude existing participants)
    @users = User.where.not(id: @participants.select(:user_id)).order(:first_name, :last_name)
  end

  def add_participant
    @participant = @event.event_participants.build(participant_params)
    
    if @participant.save
      redirect_to participants_admin_event_path(@event), notice: 'Participant added successfully.'
    else
      redirect_to participants_admin_event_path(@event), alert: 'Failed to add participant.'
    end
  end

  def bulk_invite
    user_ids = params[:user_ids] || []
    
    if user_ids.empty?
      redirect_to admin_event_path(@event), alert: 'No users selected for invitation.'
      return
    end

    success_count = 0
    user_ids.each do |user_id|
      user = User.find(user_id)
      participant = @event.event_participants.find_or_initialize_by(user: user)
      
      if participant.new_record?
        participant.role = 'attendee'
        participant.rsvp_status = 'pending'
        participant.invited_at = Time.current
        if participant.save
          success_count += 1
          # FIXED: Actually send invitation email (will implement with Sidekiq)
          InvitationMailer.event_invitation(participant).deliver_later
        end
      end
    end

    redirect_to admin_event_path(@event), 
                notice: "Successfully invited #{success_count} users to the event."
  end

  def export_participants
    @participants = @event.event_participants.includes(:user)

    respond_to do |format|
      format.csv do
        csv_data = CSV.generate(headers: true) do |csv|
          # FIXED: Use participant.rsvp_status instead of user.rsvp_status
          csv << ['Name', 'Email', 'Company', 'Phone', 'RSVP Status', 'Role', 'Checked In', 'Check-in Time']
          
          @participants.each do |participant|
            csv << [
              participant.user.full_name,
              participant.user.email,
              participant.user.company,
              participant.user.phone,
              participant.rsvp_status.humanize,  # From event_participant, not user
              participant.role.humanize,
              participant.checked_in? ? 'Yes' : 'No',
              participant.checked_in_at&.strftime('%m/%d/%Y %I:%M %p')
            ]
          end
        end

        send_data csv_data, 
                  filename: "#{@event.name.parameterize}-participants-#{Date.current}.csv",
                  type: 'text/csv'
      end
    end
  end

  def cockpit
    @vendor_events = @event.vendor_events
                           .includes(:vendor, :broadcasts)
                           .order(:category, 'vendors.name')

    @checked_in_count  = @event.event_participants.checked_in.count
    @total_rsvped      = @event.event_participants.where(rsvp_status: [:yes, :maybe]).count
    @recent_checkins   = @event.event_participants.checked_in
                               .includes(:user)
                               .order(checked_in_at: :desc)
                               .limit(8)

    @recent_broadcasts = Broadcast.joins(:vendor_event)
                                  .where(vendor_events: { event_id: @event.id })
                                  .where.not(sent_at: nil)
                                  .order(sent_at: :desc)
                                  .limit(10)
  end

  def qr_code
    @event_url = public_event_url(@event.slug, host: request.base_url)
    render layout: 'print'
  end

  private

  def set_event
    @event = Event.find_by!(slug: params[:id])
  end

  def load_venues
    @venues = Venue.order(:name)
    
    if @venues.empty?
      flash.now[:warning] = "No venues available. Please create a venue first."
    end
  end

  def load_users
    @users = User.order(:first_name, :last_name)
  end

  def participant_params
    params.require(:event_participant).permit(:user_id, :role)
  end

  def event_params
    p = params.require(:event).permit(
      :name,
      :description,
      :event_type,
      :external_url,
      :venue_id,
      :event_date,
      :end_date,
      :start_time,
      :end_time,
      :max_attendees,
      :rsvp_deadline,
      :public_rsvp_enabled,
      :lifecycle_status,
      custom_questions: [],
      category_ids: []
    )
    p[:category_ids]&.reject!(&:blank?)
    p
  end

  # Pre-populate a new event with smart defaults from the creator's recent events.
  # Returns the source event name (string) if defaults were applied, nil otherwise.
  def apply_event_defaults(event)
    recent = Event.where(creator: current_user)
                  .where.not(event_date: nil)
                  .order(event_date: :desc)
                  .limit(5)
                  .to_a

    return nil if recent.empty?

    # event_type: most common among recent events
    event.event_type = recent.group_by(&:event_type)
                             .max_by { |_, v| v.size }
                             .first

    # venue: most recently used
    last_with_venue = recent.find { |e| e.venue_id.present? }
    event.venue_id = last_with_venue&.venue_id

    # max_attendees: average of recent events that have it, rounded to nearest 10
    attendee_counts = recent.map(&:max_attendees).compact
    if attendee_counts.any?
      avg = attendee_counts.sum.to_f / attendee_counts.size
      event.max_attendees = [(avg / 10.0).round * 10, 10].max
    end

    # start_time: most common hour:minute across recent events
    start_times = recent.map(&:start_time).compact
    if start_times.any?
      event.start_time = start_times.group_by { |t| t.strftime('%H:%M') }
                                    .max_by { |_, v| v.size }
                                    .last.first
    end

    # end_time: most common
    end_times = recent.map(&:end_time).compact
    if end_times.any?
      event.end_time = end_times.group_by { |t| t.strftime('%H:%M') }
                                .max_by { |_, v| v.size }
                                .last.first
    end

    # public_rsvp_enabled: true if majority of recent events had it on
    event.public_rsvp_enabled = recent.count(&:public_rsvp_enabled?) > recent.size / 2

    recent.first.name
  end
end
