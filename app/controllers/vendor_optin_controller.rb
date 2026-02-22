class VendorOptinController < ApplicationController
  skip_before_action :authenticate_user!
  layout 'optin'
  before_action :find_vendor_event

  def show
    # If they've already opted in at this event, go straight to thanks
    if (existing = find_existing_opt_in)
      # Associate with this vendor too if they haven't been yet
      VendorOptIn.find_or_create_by(vendor_event: @vendor_event, con_opt_in: existing) do |voi|
        voi.scanned_at = Time.current
      end
      redirect_to vendor_optin_thanks_path(@vendor_event.qr_token),
                  notice: "Welcome back! You're already on the list."
      return
    end

    @con_opt_in = ConOptIn.new
  end

  def create
    # Check if this phone/email already opted into this event
    existing = find_existing_opt_in

    if existing
      # Just add the vendor association and redirect
      VendorOptIn.find_or_create_by(vendor_event: @vendor_event, con_opt_in: existing) do |voi|
        voi.scanned_at = Time.current
      end
      redirect_to vendor_optin_thanks_path(@vendor_event.qr_token),
                  notice: "You're already on the list — added to this vendor too!"
      return
    end

    @con_opt_in = ConOptIn.new(opt_in_params)
    @con_opt_in.event        = @vendor_event.event
    @con_opt_in.vendor_event = @vendor_event
    @con_opt_in.opted_in_at  = Time.current

    # Link to existing user account if phone/email matches
    @con_opt_in.user = find_matching_user

    if @con_opt_in.save
      # Create the vendor association
      VendorOptIn.create!(
        vendor_event: @vendor_event,
        con_opt_in:   @con_opt_in,
        scanned_at:   Time.current
      )
      redirect_to vendor_optin_thanks_path(@vendor_event.qr_token)
    else
      render :show, status: :unprocessable_entity
    end
  end

  def thanks
    # @vendor_event already loaded by before_action
    @opt_in_count = @vendor_event.opt_in_count
  end

  private

  def find_vendor_event
    @vendor_event = VendorEvent.includes(vendor: :user, event: {}).find_by(qr_token: params[:token])
    unless @vendor_event
      redirect_to root_path, alert: 'Invalid QR code.'
    end
  end

  def find_existing_opt_in
    phone = opt_in_params[:phone].presence rescue nil
    email = opt_in_params[:email].presence rescue nil

    if phone.present?
      ConOptIn.find_by(event: @vendor_event.event, phone: phone)
    elsif email.present?
      ConOptIn.find_by(event: @vendor_event.event, email: email)
    end
  end

  def find_matching_user
    phone = opt_in_params[:phone].presence
    email = opt_in_params[:email].presence
    User.find_by(email: email) || User.find_by(phone: phone)
  end

  def opt_in_params
    params.require(:con_opt_in).permit(:name, :phone, :email)
  end
end
