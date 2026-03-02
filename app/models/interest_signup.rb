class InterestSignup < ApplicationRecord
  validates :name,  presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "doesn't look like a valid email" },
                    allow_blank: true
  validate  :email_or_phone_present

  normalizes :email, with: ->(e) { e.strip.downcase }
  normalizes :phone, with: ->(p) { p.gsub(/\D/, '').presence }

  scope :recent,    -> { order(created_at: :desc) }
  scope :with_email, -> { where.not(email: [nil, '']) }
  scope :with_phone, -> { where.not(phone: [nil, '']) }

  private

  def email_or_phone_present
    if email.blank? && phone.blank?
      errors.add(:base, "Please provide at least an email or phone number")
    end
  end
end
