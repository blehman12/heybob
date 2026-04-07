class Vendor::VendorsController < Vendor::BaseController
  before_action :find_vendor, only: [:show, :edit, :update, :analytics]

  def new
    @vendor = Vendor.new
  end

  def create
    @vendor = Vendor.new(vendor_params)
    @vendor.user = current_user

    if @vendor.save
      redirect_to vendor_vendor_path(@vendor), notice: 'Vendor profile created!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @vendor_events = @vendor.vendor_events
                            .includes(:event)
                            .order('events.event_date DESC')
  end

  def analytics
    @vendor_events = @vendor.vendor_events
                            .includes(:event, :broadcasts => :broadcast_receipts)
                            .order('events.event_date DESC')

    # All-time opt-ins across all events
    @total_opt_ins = ConOptIn.joins(:vendor_events)
                             .where(vendor_events: { vendor_id: @vendor.id })
                             .distinct.count

    # Phone vs email split (all time)
    all_opt_ins = ConOptIn.joins(:vendor_events)
                          .where(vendor_events: { vendor_id: @vendor.id })
                          .distinct
    @phone_count = all_opt_ins.where.not(phone: [nil, '']).count
    @email_count = all_opt_ins.where.not(email:  [nil, '']).count
    @both_count  = all_opt_ins.where.not(phone: [nil, '']).where.not(email: [nil, '']).count

    # Broadcasts across all events
    all_broadcasts = Broadcast.joins(:vendor_event)
                              .where(vendor_events: { vendor_id: @vendor.id })
                              .where(status: :sent)
    @total_broadcasts = all_broadcasts.count

    # Delivery rate across all events
    all_receipts    = BroadcastReceipt.joins(:broadcast => :vendor_event)
                                      .where(vendor_events: { vendor_id: @vendor.id })
    total_receipts  = all_receipts.count
    delivered       = all_receipts.where(status: :delivered).count
    @delivery_rate  = total_receipts > 0 ? (delivered.to_f / total_receipts * 100).round : nil

    # Per-event breakdown
    @event_rows = @vendor_events.map do |ve|
      opt_ins       = ve.con_opt_ins
      broadcasts    = ve.broadcasts.where(status: :sent)
      receipts      = BroadcastReceipt.joins(:broadcast)
                                      .where(broadcasts: { vendor_event_id: ve.id })
      total_r       = receipts.count
      delivered_r   = receipts.where(status: :delivered).count
      rate          = total_r > 0 ? (delivered_r.to_f / total_r * 100).round : nil
      {
        vendor_event: ve,
        event:        ve.event,
        opt_ins:      opt_ins.count,
        broadcasts:   broadcasts.count,
        delivery_rate: rate
      }
    end

    # Recent broadcasts across all events (last 10)
    @recent_broadcasts = Broadcast.joins(:vendor_event)
                                  .where(vendor_events: { vendor_id: @vendor.id })
                                  .where(status: :sent)
                                  .includes(:vendor_event => :event, :broadcast_receipts => [])
                                  .order(sent_at: :desc)
                                  .limit(10)
  end

  def edit
  end

  def update
    if @vendor.update(vendor_params)
      redirect_to vendor_vendor_path(@vendor), notice: 'Profile updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def vendor_params
    params.require(:vendor).permit(
      :name, :description, :hook_line, :website, :hero_image,
      :participant_type, :instagram_handle, :twitter_handle, :tiktok_handle
    )
  end
end
