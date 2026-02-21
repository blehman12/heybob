class Vendor::BaseController < ApplicationController
  layout 'vendor_dashboard'
  before_action :authenticate_user!

  private

  # Finds vendor by id, ensures current user has access
  def find_vendor
    @vendor = Vendor.find(params[:vendor_id] || params[:id])
    unless @vendor.accessible_by?(current_user)
      redirect_to vendor_root_path, alert: 'Access denied.'
    end
  end

  # Finds vendor_event, ensures current user has access via vendor
  def find_vendor_event
    @vendor_event = VendorEvent.includes(:vendor, :event).find(params[:vendor_event_id] || params[:id])
    unless @vendor_event.vendor.accessible_by?(current_user)
      redirect_to vendor_root_path, alert: 'Access denied.'
    end
    @vendor = @vendor_event.vendor
  end
end
