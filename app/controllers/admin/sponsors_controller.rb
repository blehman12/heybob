class Admin::SponsorsController < Admin::BaseController

  def index
    @sponsors = Sponsor.with_attached_logo
                       .includes(:events)
                       .by_tier
                       .page(params[:page]).per(25)
  end

  def show
    @sponsor = Sponsor.includes(sponsor_events: :event).find(params[:id])
    @all_events = Event.order(:name)
  end

  def new
    @sponsor = Sponsor.new
  end

  def create
    @sponsor = Sponsor.new(sponsor_params)
    if @sponsor.save
      redirect_to admin_sponsor_path(@sponsor), notice: 'Sponsor created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @sponsor = Sponsor.find(params[:id])
  end

  def update
    @sponsor = Sponsor.find(params[:id])
    if @sponsor.update(sponsor_params)
      redirect_to admin_sponsor_path(@sponsor), notice: 'Sponsor updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sponsor = Sponsor.find(params[:id])
    @sponsor.destroy
    redirect_to admin_sponsors_path, notice: 'Sponsor deleted.'
  end

  private

  def sponsor_params
    params.require(:sponsor).permit(
      :name, :description, :website, :tier, :display_order, :is_active, :logo
    )
  end
end
