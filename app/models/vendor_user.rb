class VendorUser < ApplicationRecord
  belongs_to :vendor
  belongs_to :user

  validates :vendor_id, uniqueness: { scope: :user_id }
end
