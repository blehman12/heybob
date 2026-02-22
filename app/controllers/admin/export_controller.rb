class Admin::ExportController < Admin::BaseController
  before_action :ensure_super_admin!

  SCHEMA_VERSION = '1.0'

  def show
    render json: full_export, status: :ok
  end

  private

  def full_export
    {
      schema_version: SCHEMA_VERSION,
      exported_at:    Time.current.iso8601,
      app:            'evm1',
      counts: {
        users:      User.count,
        events:     Event.count,
        vendors:    Vendor.count,
        categories: Category.count
      },
      categories: export_categories,
      users:      export_users,
      events:     export_events,
      vendors:    export_vendors
    }
  end

  def export_categories
    Category.includes(:parent).ordered.map do |c|
      {
        external_id: c.external_id,
        name:        c.name,
        slug:        c.slug,
        facet:       c.facet,
        parent_external_id: c.parent&.external_id,
        description: c.description,
        position:    c.position,
        active:      c.active
      }
    end
  end

  def export_users
    User.order(:created_at).map do |u|
      {
        external_id:  u.external_id,
        email:        u.email,
        first_name:   u.first_name,
        last_name:    u.last_name,
        phone:        u.phone,
        company:      u.company,
        role:         u.role,
        text_capable: u.text_capable,
        created_at:   u.created_at.iso8601,
        interest_external_ids: u.interests.pluck(:external_id)
      }
    end
  end

  def export_events
    Event.includes(:venue, :categories, vendor_events: :vendor,
                   event_participants: :user).order(:event_date).map do |e|
      {
        external_id:   e.external_id,
        name:          e.name,
        description:   e.description,
        event_type:    e.event_type,
        event_date:    e.event_date&.iso8601,
        start_time:    e.start_time&.strftime('%H:%M'),
        end_time:      e.end_time&.strftime('%H:%M'),
        rsvp_deadline: e.rsvp_deadline&.iso8601,
        max_attendees: e.max_attendees,
        external_url:  e.external_url,
        slug:          e.slug,
        venue: e.venue ? {
          name:    e.venue.name,
          address: e.venue.address
        } : nil,
        category_external_ids: e.categories.map(&:external_id),
        participants: e.event_participants.map do |ep|
          {
            user_external_id: ep.user.external_id,
            role:             ep.role,
            rsvp_status:      ep.rsvp_status,
            checked_in:       ep.checked_in?,
            checked_in_at:    ep.checked_in_at&.iso8601
          }
        end,
        vendor_events: e.vendor_events.map do |ve|
          {
            vendor_external_id: ve.vendor.external_id,
            category:           ve.category,
            table_number:       ve.table_number
          }
        end
      }
    end
  end

  def export_vendors
    Vendor.includes(:categories, :vendor_events).order(:name).map do |v|
      {
        external_id:      v.external_id,
        name:             v.name,
        participant_type: v.participant_type,
        website:          v.website,
        instagram_handle: v.instagram_handle,
        twitter_handle:   v.twitter_handle,
        tiktok_handle:    v.tiktok_handle,
        category_external_ids: v.categories.map(&:external_id),
        event_count:      v.vendor_events.count
      }
    end
  end
end
