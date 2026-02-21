class VendorEvent < ApplicationRecord
  belongs_to :vendor
  belongs_to :event
  has_many :vendor_opt_ins, dependent: :destroy
  has_many :con_opt_ins, through: :vendor_opt_ins
  has_many :broadcasts, dependent: :destroy

  validates :vendor_id, uniqueness: { scope: :event_id }
  validates :qr_token, presence: true, uniqueness: true

  serialize :metadata, coder: JSON

  before_validation :generate_qr_token, on: :create

  def booth_number
    metadata&.dig('booth_number')
  end

  def hall
    metadata&.dig('hall')
  end

  def opt_in_count
    con_opt_ins.count
  end

  private

  def generate_qr_token
    return if qr_token.present?
    loop do
      token = SecureRandom.urlsafe_base64(16)
      break self.qr_token = token unless VendorEvent.exists?(qr_token: token)
    end
  end
end
