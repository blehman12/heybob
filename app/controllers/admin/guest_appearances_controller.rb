class Admin::GuestAppearancesController < Admin::BaseController

  def create
    @appearance = GuestAppearance.new(appearance_params)
    if @appearance.save
      redirect_to admin_guest_path(@appearance.guest), notice: 'Appearance added.'
    else
      redirect_to admin_guest_path(@appearance.guest),
                  alert: @appearance.errors.full_messages.to_sentence
    end
  end

  def destroy
    @appearance = GuestAppearance.find(params[:id])
    guest = @appearance.guest
    @appearance.destroy
    redirect_to admin_guest_path(guest), notice: 'Appearance removed.'
  end

  private

  def appearance_params
    params.require(:guest_appearance).permit(:guest_id, :event_id, :notes, :display_order)
  end
end
