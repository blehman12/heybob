class Vendor::DashboardController < Vendor::BaseController

  def index
    # All vendors this user owns or has access to
    owned    = Vendor.where(user: current_user)
    shared   = Vendor.joins(:vendor_users).where(vendor_users: { user: current_user })
    @vendors = (owned + shared).uniq

    # If they only have one vendor, go straight to it
    if @vendors.count == 1
      redirect_to vendor_vendor_path(@vendors.first) and return
    end
  end

end
