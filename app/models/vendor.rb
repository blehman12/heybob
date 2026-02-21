class Vendor < ApplicationRecord
  belongs_to :user  # owner
  has_many :vendor_users, dependent: :destroy
  has_many :users, through: :vendor_users
  has_many :vendor_events, dependent: :destroy
  has_many :events, through: :vendor_events
  has_one_attached :hero_image

  validates :name, presence: true
  validates :user, presence: true

  def accessible_by?(user)
    self.user == user || vendor_users.exists?(user: user)
  end
end
