class Admin::ParticipantsController < Admin::BaseController
  def index
    @participants = EventParticipant.includes(:user, :event)

    # Filter by event
    if params[:event_id].present?
      @participants = @participants.where(event_id: params[:event_id])
    end

    # Filter by role
    if params[:role].present? && EventParticipant.roles.key?(params[:role])
      @participants = @participants.where(role: params[:role])
    end

    # Filter by RSVP status
    if params[:rsvp_status].present? && EventParticipant.rsvp_statuses.key?(params[:rsvp_status])
      @participants = @participants.where(rsvp_status: params[:rsvp_status])
    end

    # Filter by check-in status
    if params[:checked_in].present?
      @participants = params[:checked_in] == 'true' ? @participants.checked_in : @participants.not_checked_in
    end

    # Search by name or email
    if params[:search].present?
      search = "%#{params[:search].downcase}%"
      @participants = @participants.where(
        "LOWER(guest_name) LIKE :q OR LOWER(users.email) LIKE :q OR LOWER(users.first_name) LIKE :q OR LOWER(users.last_name) LIKE :q",
        q: search
      ).references(:user)
    end

    @total_count    = @participants.count
    @confirmed      = @participants.confirmed.count
    @checked_in     = @participants.checked_in.count
    @vendors        = @participants.vendors.count

    @participants = @participants.order('events.event_date DESC, users.last_name ASC')
                                 .page(params[:page]).per(50)

    @events = Event.order(:name)

    respond_to do |format|
      format.html
      format.csv do
        @all = @participants.except(:limit, :offset)
        send_data generate_csv(@all), filename: "participants-#{Date.today}.csv", type: 'text/csv'
      end
    end
  end

  private

  def generate_csv(participants)
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << ['Name', 'Email', 'Phone', 'Event', 'Event Date', 'Role', 'RSVP Status', 'Checked In', 'Check-in Time', 'Guest?']
      participants.each do |p|
        csv << [
          p.display_name,
          p.display_email,
          p.display_phone,
          p.event.name,
          p.event.event_date&.strftime('%Y-%m-%d'),
          p.role,
          p.rsvp_status,
          p.checked_in? ? 'Yes' : 'No',
          p.checked_in_at&.strftime('%Y-%m-%d %H:%M'),
          p.is_guest? ? 'Yes' : 'No'
        ]
      end
    end
  end
