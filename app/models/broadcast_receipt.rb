class BroadcastReceipt < ApplicationRecord
  belongs_to :broadcast
  belongs_to :con_opt_in

  enum status: { pending: 0, delivered: 1, failed: 2 }

  validates :broadcast_id, uniqueness: { scope: :con_opt_in_id }

  scope :failed, -> { where(status: :failed) }
  scope :delivered, -> { where(status: :delivered) }
end
