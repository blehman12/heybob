class Sponsor < ApplicationRecord
  has_one_attached :logo
  has_many :sponsor_events, dependent: :destroy
  has_many :events, through: :sponsor_events

  validate :logo_acceptable, if: -> { logo.attached? }

  enum tier: {
    title:      0,
    presenting: 1,
    gold:       2,
    silver:     3,
    general:    4
  }

  validates :name, presence: true
  validates :tier, presence: true

  scope :active,   -> { where(is_active: true) }
  scope :by_tier,  -> { order(:tier, :display_order, :name) }
  scope :for_event, ->(event) { joins(:sponsor_events).where(sponsor_events: { event_id: event.id }) }

  def tier_label
    tier.capitalize
  end

  def tier_badge_class
    case tier
    when 'title'      then 'bg-dark'
    when 'presenting' then 'bg-primary'
    when 'gold'       then 'bg-warning text-dark'
    when 'silver'     then 'bg-secondary'
    else                   'bg-light text-dark border'
    end
  end

  private

  def logo_acceptable
    acceptable_types = %w[image/jpeg image/png image/gif image/webp]
    unless logo.content_type.in?(acceptable_types)
      errors.add(:logo, 'must be a JPEG, PNG, GIF, or WebP image')
    end
    if logo.byte_size > 2.megabytes
      errors.add(:logo, 'must be smaller than 2 MB')
    end
  end
end
