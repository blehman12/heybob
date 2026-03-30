class Guest < ApplicationRecord
  has_one_attached :photo
  has_many :guest_appearances, dependent: :destroy
  has_many :events, through: :guest_appearances

  validate :photo_acceptable, if: -> { photo.attached? }

  enum guest_type: {
    voice_actor: 0,
    musician:    1,
    industry:    2,
    artist:      3,
    performer:   4,
    other:       5
  }

  validates :name,       presence: true
  validates :guest_type, presence: true

  scope :active,   -> { where(is_active: true) }
  scope :by_type,  ->(t) { where(guest_type: t) }
  scope :ordered,  -> { order(:name) }

  def social_handles
    {
      instagram: instagram_handle,
      twitter:   twitter_handle,
      tiktok:    tiktok_handle,
      youtube:   youtube_handle
    }.reject { |_, v| v.blank? }
  end

  def guest_type_label
    case guest_type
    when 'voice_actor' then 'Voice Actor'
    when 'musician'    then 'Musician'
    when 'industry'    then 'Industry Guest'
    when 'artist'      then 'Guest Artist'
    when 'performer'   then 'Performer'
    else                    'Guest'
    end
  end

  def guest_type_badge_class
    case guest_type
    when 'voice_actor' then 'bg-primary'
    when 'musician'    then 'bg-success'
    when 'industry'    then 'bg-info text-dark'
    when 'artist'      then 'bg-warning text-dark'
    when 'performer'   then 'bg-danger'
    else                    'bg-secondary'
    end
  end

  private

  def photo_acceptable
    acceptable_types = %w[image/jpeg image/png image/gif image/webp]
    unless photo.content_type.in?(acceptable_types)
      errors.add(:photo, 'must be a JPEG, PNG, GIF, or WebP image')
    end
    if photo.byte_size > 5.megabytes
      errors.add(:photo, 'must be smaller than 5 MB')
    end
  end
end
