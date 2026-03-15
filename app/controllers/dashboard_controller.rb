class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @upcoming_participants = current_user.event_participants
                                         .includes(event: :venue)
                                         .joins(:event)
                                         .where('events.event_date >= ?', Date.today)
                                         .order('events.event_date ASC')

    @past_participants = current_user.event_participants
                                     .includes(event: :venue)
                                     .joins(:event)
                                     .where('events.event_date < ?', Date.today)
                                     .order('events.event_date DESC')
                                     .limit(5)
  end
end
