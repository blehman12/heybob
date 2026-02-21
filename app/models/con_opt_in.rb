class ConOptIn < ApplicationRecord
  belongs_to :event
  belongs_to :vendor_event        # referring vendor (first scan)
  belongs_to :user, optional: true  # nil for anonymous visitors
  has_many :vendor_opt_ins, dependent: :destroy
  has_many :vendor_events, through: :vendor_opt_ins
  has_many :broadcast_receipts, dependent: :destroy

  validates :name, presence: true
  validates :event_id, presence: true
  validates :vendor_event_id, presence: true
  validate  :phone_or_email_present
  validates :phone, uniqueness: { scope: :event_id }, allow_nil: true
  validates :email, uniqueness: { scope: :event_id }, allow_nil: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  before_validation :set_opted_in_at

  def display_contact
    phone.presence || email.presence || 'No contact info'
  end

  private

  def phone_or_email_present
    if phone.blank? && email.blank?
      errors.add(:base, 'Please provide a phone number or email address')
    end
  end

  def set_opted_in_at
    self.opted_in_at ||= Time.current
  end
end
