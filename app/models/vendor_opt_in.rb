class VendorOptIn < ApplicationRecord
  belongs_to :vendor_event
  belongs_to :con_opt_in

  validates :vendor_event_id, uniqueness: { scope: :con_opt_in_id }

  before_validation :set_scanned_at

  private

  def set_scanned_at
    self.scanned_at ||= Time.current
  end
end
