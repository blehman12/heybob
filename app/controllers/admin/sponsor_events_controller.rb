class Admin::SponsorEventsController < Admin::BaseController

  def create
    @sponsor_event = SponsorEvent.new(sponsor_event_params)
    if @sponsor_event.save
      redirect_to admin_sponsor_path(@sponsor_event.sponsor), notice: 'Event linked.'
    else
      redirect_to admin_sponsor_path(@sponsor_event.sponsor),
                  alert: @sponsor_event.errors.full_messages.to_sentence
    end
  end

  def destroy
    @sponsor_event = SponsorEvent.find(params[:id])
    sponsor = @sponsor_event.sponsor
    @sponsor_event.destroy
    redirect_to admin_sponsor_path(sponsor), notice: 'Event removed.'
  end

  private

  def sponsor_event_params
    params.require(:sponsor_event).permit(:sponsor_id, :event_id, :display_order)
  end
end
