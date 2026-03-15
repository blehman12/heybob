class Venue < ApplicationRecord
  has_one_attached :photo
  has_many :events, dependent: :destroy

  validate :photo_acceptable, if: -> { photo.attached? }

  validates :name, :address, presence: true
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :name, uniqueness: true

  scope :available_for_date, ->(date) { 
    where.not(id: Event.where(event_date: date.beginning_of_day..date.end_of_day).select(:venue_id))
  }

  def photo_acceptable
    acceptable_types = %w[image/jpeg image/png image/gif image/webp]
    unless photo.content_type.in?(acceptable_types)
      errors.add(:photo, "must be a JPEG, PNG, GIF, or WebP image")
    end
    if photo.byte_size > 5.megabytes
      errors.add(:photo, "must be smaller than 5 MB")
    end
  end

  def full_address
    "#{name}, #{address}"
  end

  def events_count
    events.count
  end

  def upcoming_events
    events.upcoming.order(:event_date)
  end
end

  # Helper methods for admin interface
  def events_count
    events.count
  end
  
  def upcoming_events
    events.where('event_date >= ?', Time.current)
  end
  
  def full_address
    address
  end
