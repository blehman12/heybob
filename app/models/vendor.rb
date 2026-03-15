class Vendor < ApplicationRecord
  include HasExternalId
  belongs_to :user  # owner
  has_many :vendor_users, dependent: :destroy
  has_many :users, through: :vendor_users
  has_many :vendor_events, dependent: :destroy
  has_many :events, through: :vendor_events
  has_one_attached :hero_image

  validate :hero_image_acceptable, if: -> { hero_image.attached? }
  has_many :categorizations, as: :categorizable, dependent: :destroy
  has_many :categories, through: :categorizations

  enum participant_type: {
    business: 0,   # Dealer's room — company/commercial vendor
    artist:   1    # Artist Alley — individual creator
  }

  validates :name, presence: true
  validates :user, presence: true

  def accessible_by?(user)
    self.user == user || vendor_users.exists?(user: user)
  end

  def social_handles
    {
      instagram: instagram_handle,
      twitter:   twitter_handle,
      tiktok:    tiktok_handle
    }.reject { |_, v| v.blank? }
  end

  def artist?
    participant_type == 'artist'
  end

  def hero_image_acceptable
    acceptable_types = %w[image/jpeg image/png image/gif image/webp]
    unless hero_image.content_type.in?(acceptable_types)
      errors.add(:hero_image, "must be a JPEG, PNG, GIF, or WebP image")
    end
    if hero_image.byte_size > 5.megabytes
      errors.add(:hero_image, "must be smaller than 5 MB")
    end
  end

  def primary_web_presence
    if artist?
      social_handles.values.first || website
    else
      website
    end
  end
end
