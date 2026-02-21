class Vendor::VendorsController < Vendor::BaseController
  before_action :find_vendor, only: [:show, :edit, :update]

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
    params.require(:vendor).permit(:name, :description, :hook_line, :website, :hero_image)
  end
end
