class VendorFollow < ApplicationRecord
  belongs_to :vendor

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, uniqueness: { scope: :vendor_id, message: "is already following this vendor" }, allow_nil: true
  validates :email, uniqueness: { scope: :vendor_id, message: "is already following this vendor" }, allow_nil: true
  validate  :phone_or_email_present

  before_validation :set_followed_at
  before_validation :normalize_blanks

  private

  def phone_or_email_present
    if phone.blank? && email.blank?
      errors.add(:base, 'Please provide a phone number or email address')
    end
  end

  def set_followed_at
    self.followed_at ||= Time.current
  end

  def normalize_blanks
    self.phone = nil if phone.blank?
    self.email = nil if email.blank?
  end
end
