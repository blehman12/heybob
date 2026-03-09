class Vendor::VendorEventsController < Vendor::BaseController
  before_action :find_vendor,       only: [:new, :create]
  before_action :find_vendor_event, only: [:show, :edit, :update, :qr_code, :broadcast, :export_contacts]

  def new
    @vendor_event = VendorEvent.new
    # Default category based on vendor's participant type
    @vendor_event.category = @vendor.artist? ? :artist_alley : :dealer
    @available_events = Event.upcoming.order(:event_date)
  end

  def create
    @vendor_event = VendorEvent.new(vendor_event_params)
    @vendor_event.vendor = @vendor

    if @vendor_event.save
      redirect_to vendor_vendor_event_path(@vendor_event),
                  notice: "You're registered for #{@vendor_event.event.name}!"
    else
      @available_events = Event.upcoming.order(:event_date)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @recent_broadcasts = @vendor_event.broadcasts
                                      .sent
                                      .recent
                                      .includes(:broadcast_receipts)
                                      .limit(10)
    @new_broadcast = Broadcast.new

    opt_ins = @vendor_event.con_opt_ins
    @phone_count = opt_ins.where.not(phone: [nil, '']).count
    @email_count = opt_ins.where.not(email: [nil, '']).count
    @opt_in_timeline = opt_ins
                         .where.not(opted_in_at: nil)
                         .group(Arel.sql("date_trunc('hour', opted_in_at)"))
                         .order(Arel.sql("date_trunc('hour', opted_in_at)"))
                         .count

    @reached_count = BroadcastReceipt
                       .joins(:broadcast)
                       .where(broadcasts: { vendor_event_id: @vendor_event.id })
                       .where(status: :delivered)
                       .distinct
                       .count(:con_opt_in_id)
  end

  def edit
    # @vendor_event already loaded by find_vendor_event
  end

  def update
    if @vendor_event.update(vendor_event_update_params)
      redirect_to vendor_vendor_event_path(@vendor_event), notice: 'Logistics updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def export_contacts
    opt_ins = @vendor_event.con_opt_ins.order(:opted_in_at)
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['Name', 'Phone', 'Email', 'Opted In At']
      opt_ins.each do |o|
        csv << [
          o.name,
          o.phone,
          o.email,
          o.opted_in_at&.strftime('%Y-%m-%d %H:%M')
        ]
      end
    end
    send_data csv_data,
              filename: "#{@vendor_event.event.name.parameterize}-contacts-#{Date.today}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  def qr_code
    @optin_url = vendor_optin_url(@vendor_event.qr_token,
                                  host: request.base_url)
  end

  def broadcast
    @broadcast = Broadcast.new(broadcast_params)
    @broadcast.vendor_event = @vendor_event
    @broadcast.sent_at      = Time.current

    recipients = @broadcast.entire_con? \
      ? @vendor_event.event.con_opt_ins
      : @vendor_event.con_opt_ins

    @broadcast.recipient_count = recipients.count

    if @broadcast.save
      recipients.each do |opt_in|
        BroadcastReceipt.create!(
          broadcast:   @broadcast,
          con_opt_in:  opt_in,
          status:      :pending
        )
      end

      BroadcastSmsJob.perform_later(@broadcast.id)

      redirect_to vendor_vendor_event_path(@vendor_event),
                  notice: "Broadcast sent to #{@broadcast.recipient_count} people!"
    else
      @recent_broadcasts = @vendor_event.broadcasts.sent.recent.limit(10)
      @new_broadcast = @broadcast
      render :show, status: :unprocessable_entity
    end
  end

  private

  def vendor_event_params
    allowed = params.require(:vendor_event).permit(:event_id, :category)
    allowed.merge(metadata: extract_metadata({}))
  end

  def vendor_event_update_params
    allowed = params.require(:vendor_event).permit(:category)
    allowed.merge(metadata: extract_metadata(@vendor_event.metadata || {}))
  end

  def extract_metadata(base)
    ve = params[:vendor_event] || {}
    base.merge(
      'booth_number'  => ve[:booth_number].presence,
      'hall'          => ve[:hall].presence,
      'load_in_date'  => ve[:load_in_date].presence,
      'load_in_time'  => ve[:load_in_time].presence,
      'load_in_notes' => ve[:load_in_notes].presence
    ).compact
  end

  def broadcast_params
    params.require(:broadcast).permit(:message, :channel, :scope)
  end
end
