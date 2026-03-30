class PublicGuestsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @guests = Guest.active
                   .with_attached_photo
                   .includes(guest_appearances: :event)
                   .ordered

    if params[:type].present? && Guest.guest_types.key?(params[:type])
      @guests = @guests.by_type(params[:type])
    end

    @active_type = params[:type]
  end

  def show
    @guest = Guest.includes(guest_appearances: :event).find(params[:id])

    @upcoming_appearances = @guest.guest_appearances
                                  .joins(:event)
                                  .includes(:event)
                                  .where('events.event_date >= ?', Date.today)
                                  .order('events.event_date ASC')
  end
end
