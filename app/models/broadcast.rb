class Broadcast < ApplicationRecord
  belongs_to :vendor_event
  has_many :broadcast_receipts, dependent: :destroy

  enum channel: { sms: 0, email: 1, feed: 2 }
  enum scope: { booth_visitors: 0, entire_con: 1 }

  validates :message, presence: true, length: { maximum: 160, message: 'Keep SMS messages under 160 characters' }
  validates :channel, presence: true

  scope :sent, -> { where.not(sent_at: nil) }
  scope :pending, -> { where(sent_at: nil) }
  scope :recent, -> { order(sent_at: :desc) }

  def sent?
    sent_at.present?
  end

  def recipients
    if entire_con?
      vendor_event.event.con_opt_ins
    else
      vendor_event.con_opt_ins
    end
  end
end
