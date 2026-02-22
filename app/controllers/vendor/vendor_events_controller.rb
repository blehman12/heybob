class Vendor::VendorEventsController < Vendor::BaseController
  before_action :find_vendor,       only: [:new, :create]
  before_action :find_vendor_event, only: [:show, :qr_code, :broadcast]

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
                                      .limit(10)
    @new_broadcast = Broadcast.new
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
    params.require(:vendor_event).permit(:event_id, :category).tap do |p|
      metadata = {}
      metadata['booth_number'] = params[:booth_number].strip  if params[:booth_number].present?
      metadata['hall']         = params[:hall].strip          if params[:hall].present?
      p[:metadata] = metadata if metadata.any?
    end
  end

  def broadcast_params
    params.require(:broadcast).permit(:message, :channel, :scope)
  end
end
