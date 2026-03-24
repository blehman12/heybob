class DashboardController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    if current_user
      # Admins and vendors go to their own dashboards
      return redirect_to admin_root_path  if current_user.super_admin? || current_user.event_admin? || current_user.venue_admin?
      return redirect_to vendor_root_path if current_user.vendor_admin?

      load_attendee_dashboard
    else
      load_public_discovery
    end
  end

  private

  def load_attendee_dashboard
    all_upcoming = current_user.event_participants
                               .includes(event: [:venue, :categories])
                               .joins(:event)
                               .where('events.event_date >= ?', Date.today)
                               .order('events.event_date ASC')

    @pending_participants  = all_upcoming.select { |p| p.rsvp_status.to_s == 'pending' }
    @confirmed_participants = all_upcoming.select { |p| %w[yes maybe].include?(p.rsvp_status.to_s) }

    @past_participants = current_user.event_participants
                                     .includes(event: :venue)
                                     .joins(:event)
                                     .where('events.event_date < ?', Date.today)
                                     .order('events.event_date DESC')
                                     .limit(5)

    rsvped_event_ids = current_user.event_participants.pluck(:event_id)
    base_discover = Event.includes(:venue, :categories)
                         .hosted.published
                         .where('event_date >= ?', Date.today)
                         .where.not(id: rsvped_event_ids)
                         .order(:event_date)

    user_interest_ids = current_user.interests.pluck(:id)
    @has_interests = user_interest_ids.any?

    if @has_interests && params[:show_all] != 'true'
      @discover_events  = base_discover.joins(:categorizations)
                                       .where(categorizations: { category_id: user_interest_ids })
                                       .distinct
      @showing_matched  = true
    else
      @discover_events  = base_discover
      @showing_matched  = false
    end
  end

  def load_public_discovery
    @discover_events = Event.includes(:venue, :categories)
                            .hosted.published
                            .where('event_date >= ?', Date.today)
                            .order(:event_date)

    if params[:tag].present?
      @active_tag = Category.find_by(slug: params[:tag])
      if @active_tag
        @discover_events = @discover_events.joins(:categorizations)
                                           .where(categorizations: { category_id: @active_tag.id })
      end
    end

    @categories = Category.active.order(:name)
  end
end
