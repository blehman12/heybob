class VisitorOptInsController < ApplicationController
  layout 'visitor'
  skip_before_action :authenticate_user!
  before_action :find_vendor_event, only: [:show, :create, :welcome]
  before_action :find_event_for_feed, only: [:feed]

  # GET /join/:qr_token
  # Vendor-branded opt-in landing page
  def show
    @con_opt_in   = ConOptIn.new
    @sms_opted_in = false
  end

  # POST /join/:qr_token
  def create
    sms_opted_in = params[:sms_opt_in] == "1"

    attrs = opt_in_params
    # Strip phone if user did not check the SMS opt-in box
    attrs = attrs.merge(phone: nil) unless sms_opted_in

    # No contact info at all — just send them to the feed (no record needed)
    if attrs[:phone].blank? && attrs[:email].blank?
      redirect_to event_feed_path(@vendor_event.event.slug),
                  notice: 'Welcome! Browse the event below.'
      return
    end

    @con_opt_in = ConOptIn.new(attrs)
    @con_opt_in.event        = @vendor_event.event
    @con_opt_in.vendor_event = @vendor_event
    @con_opt_in.opted_in_at  = Time.current

    # Match to existing User account by phone or email (optional enrichment)
    @con_opt_in.user = find_matching_user(@con_opt_in)

    if @con_opt_in.save
      session[:sms_opted_in] = sms_opted_in

      # Create VendorOptIn join record (first booth scan)
      VendorOptIn.find_or_create_by(
        vendor_event: @vendor_event,
        con_opt_in:   @con_opt_in
      ) { |v| v.scanned_at = Time.current }

      redirect_to vendor_optin_welcome_path(@vendor_event.qr_token)
    else
      # Handle deduplication — same phone/email already opted in
      existing = find_existing_opt_in(@con_opt_in)

      if existing
        # Add association to this vendor if they haven't scanned here before
        VendorOptIn.find_or_create_by(
          vendor_event: @vendor_event,
          con_opt_in:   existing
        ) { |v| v.scanned_at = Time.current }

        redirect_to vendor_optin_welcome_path(@vendor_event.qr_token),
                    notice: 'Welcome back! You are already in the con feed.'
      else
        @sms_opted_in = sms_opted_in
        render :show, status: :unprocessable_entity
      end
    end
  end

  # GET /join/:qr_token/welcome
  def welcome
    @sms_opted_in = session.delete(:sms_opted_in)
  end

  # GET /feed/:event_slug
  # Public live feed — no auth required
  def feed
    @broadcasts = Broadcast
      .joins(vendor_event: [:vendor, :event])
      .where(vendor_events: { event_id: @event.id }, sent_at: ..Time.current)
      .where.not(sent_at: nil)
      .order(sent_at: :desc)
      .limit(50)
      .includes(vendor_event: :vendor)
  end

  private

  def find_vendor_event
    @vendor_event = VendorEvent.includes(:vendor, :event).find_by(qr_token: params[:qr_token])

    unless @vendor_event
      render plain: 'QR code not found. Please ask the vendor for a new code.', status: :not_found
    end
  end

  def find_event_for_feed
    @event = Event.find_by(slug: params[:event_slug])
    unless @event
      render plain: 'Event not found.', status: :not_found
    end
  end

  def opt_in_params
    params.require(:con_opt_in).permit(:name, :phone, :email)
  end

  # Try to match an anonymous opt-in to an existing User account
  def find_matching_user(opt_in)
    return nil if opt_in.phone.blank? && opt_in.email.blank?
    User.find_by(phone: opt_in.phone) if opt_in.phone.present?
    # Corner case: email matching — deferred
  end

  # Check if this person already opted into this event
  def find_existing_opt_in(opt_in)
    event = opt_in.event || @vendor_event.event
    if opt_in.phone.present?
      ConOptIn.find_by(event: event, phone: opt_in.phone)
    elsif opt_in.email.present?
      ConOptIn.find_by(event: event, email: opt_in.email)
    end
  end
end
