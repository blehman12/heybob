class Admin::GuestsController < Admin::BaseController

  def index
    @guests = Guest.with_attached_photo
                   .includes(:events)
                   .order(:name)
                   .page(params[:page]).per(25)
  end

  def show
    @guest = Guest.includes(guest_appearances: :event).find(params[:id])
    @all_events = Event.order(:name)
  end

  def new
    @guest = Guest.new
  end

  def create
    @guest = Guest.new(guest_params)
    if @guest.save
      redirect_to admin_guest_path(@guest), notice: 'Guest created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @guest = Guest.find(params[:id])
  end

  def update
    @guest = Guest.find(params[:id])
    if @guest.update(guest_params)
      redirect_to admin_guest_path(@guest), notice: 'Guest updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @guest = Guest.find(params[:id])
    @guest.destroy
    redirect_to admin_guests_path, notice: 'Guest deleted.'
  end

  private

  def guest_params
    params.require(:guest).permit(
      :name, :bio, :guest_type, :website,
      :instagram_handle, :twitter_handle, :tiktok_handle, :youtube_handle,
      :is_active, :photo
    )
  end
end
