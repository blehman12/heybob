class VendorEvent < ApplicationRecord
  belongs_to :vendor
  belongs_to :event
  has_many :vendor_opt_ins, dependent: :destroy
  has_many :con_opt_ins, through: :vendor_opt_ins
  has_many :broadcasts, dependent: :destroy

  enum category: {
    dealer:      0,  # Dealer's Room
    artist_alley: 1, # Artist Alley
    sponsor:     2,  # Event sponsor
    exhibitor:   3,  # Non-selling exhibitor (gaming room, club table, etc.)
    panelist:    4   # Panel/programming participant
  }

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

  # Human-friendly label for display
  def category_label
    case category
    when 'dealer'       then "Dealer's Room"
    when 'artist_alley' then 'Artist Alley'
    when 'sponsor'      then 'Sponsor'
    when 'exhibitor'    then 'Exhibitor'
    when 'panelist'     then 'Panelist'
    end
  end

  # Copy for QR opt-in landing page
  def optin_headline
    case category
    when 'artist_alley'
      "Follow #{vendor.name} for art updates & commission info"
    when 'dealer'
      "Join #{vendor.name}'s list for deals & event updates"
    when 'sponsor'
      "Connect with #{vendor.name}"
    else
      "Stay connected with #{vendor.name}"
    end
  end

  def optin_subtext
    case category
    when 'artist_alley'
      "Get notified about table availability, new prints, and commission openings"
    when 'dealer'
      "Be first to hear about sales, restocks, and convention specials"
    else
      "Receive updates and announcements during this event"
    end
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
