class Categorization < ApplicationRecord
  belongs_to :category
  belongs_to :categorizable, polymorphic: true

  validates :category_id, uniqueness: {
    scope: [:categorizable_type, :categorizable_id],
    message: 'already applied'
  }

  scope :for_events,  -> { where(categorizable_type: 'Event') }
  scope :for_users,   -> { where(categorizable_type: 'User') }
  scope :for_vendors, -> { where(categorizable_type: 'Vendor') }
end
