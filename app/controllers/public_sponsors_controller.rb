class PublicSponsorsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @sponsors = Sponsor.active
                       .with_attached_logo
                       .includes(sponsor_events: :event)
                       .by_tier
  end

  def show
    @sponsor = Sponsor.includes(sponsor_events: :event).find(params[:id])
  end
end
