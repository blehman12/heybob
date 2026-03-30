class GuestAppearance < ApplicationRecord
  belongs_to :guest
  belongs_to :event

  validates :guest_id, uniqueness: { scope: :event_id, message: 'is already appearing at this event' }

  default_scope { order(:display_order, :created_at) }
end
