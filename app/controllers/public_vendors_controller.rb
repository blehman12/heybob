class PublicVendorsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show, :follow]

  def index
    @vendors = Vendor.includes(:categories, :hero_image_attachment, vendor_events: :event)
                     .order(:name)

    if params[:type].present? && Vendor.participant_types.key?(params[:type])
      @vendors = @vendors.where(participant_type: params[:type])
    end

    @active_type = params[:type]
  end

  def show
    @vendor = Vendor.includes(:categories, vendor_events: :event).find_by!(slug: params[:id])
    @follow = VendorFollow.new

    @upcoming_appearances = @vendor.vendor_events
                                   .joins(:event)
                                   .includes(:event)
                                   .where('events.event_date >= ?', Date.today)
                                   .order('events.event_date ASC')
  end

  def follow
    @vendor = Vendor.find_by!(slug: params[:id])
    @follow = VendorFollow.new(follow_params)
    @follow.vendor  = @vendor
    @follow.source  = 'profile'

    if @follow.save
      redirect_to public_vendor_path(@vendor),
                  notice: "You're now following #{@vendor.name}! We'll reach out with updates."
    else
      # Duplicate — be gracious about it
      if duplicate_follow?(@follow)
        redirect_to public_vendor_path(@vendor),
                    notice: "You're already following #{@vendor.name} — we've got you covered!"
      else
        @upcoming_appearances = @vendor.vendor_events
                                       .joins(:event)
                                       .includes(:event)
                                       .where('events.event_date >= ?', Date.today)
                                       .order('events.event_date ASC')
        render :show, status: :unprocessable_entity
      end
    end
  end

  private

  def follow_params
    params.require(:vendor_follow).permit(:name, :phone, :email)
  end

  def duplicate_follow?(follow)
    return true if follow.phone.present? &&
      VendorFollow.exists?(vendor: @vendor, phone: follow.phone)
    return true if follow.email.present? &&
      VendorFollow.exists?(vendor: @vendor, email: follow.email)
    false
  end
end
