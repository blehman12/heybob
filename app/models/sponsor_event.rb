class SponsorEvent < ApplicationRecord
  belongs_to :sponsor
  belongs_to :event

  validates :sponsor_id, uniqueness: { scope: :event_id, message: 'is already sponsoring this event' }

  default_scope { order(:display_order, :created_at) }
end
