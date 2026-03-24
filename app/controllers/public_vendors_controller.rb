class PublicVendorsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @vendors = Vendor.includes(:categories, :hero_image_attachment, vendor_events: :event)
                     .order(:name)

    if params[:type].present? && Vendor.participant_types.key?(params[:type])
      @vendors = @vendors.where(participant_type: params[:type])
    end

    @active_type = params[:type]
  end

  def show
    @vendor = Vendor.includes(:categories, vendor_events: :event).find(params[:id])

    @upcoming_appearances = @vendor.vendor_events
                                   .joins(:event)
                                   .includes(:event)
                                   .where('events.event_date >= ?', Date.today)
                                   .order('events.event_date ASC')
  end
end
