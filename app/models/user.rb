# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Role hierarchy — integer values are fixed, do not reorder
  # existing admin=1 maps to super_admin so no data migration needed
  enum role: {
    attendee:     0,
    super_admin:  1,  # was 'admin' — full access
    event_admin:  2,  # can manage events and assign categories to them
    venue_admin:  3,  # can manage venues
    vendor_admin: 4   # can manage vendors
  }

  # Associations
  has_many :event_participants, dependent: :destroy
  has_many :events, through: :event_participants
  has_many :created_events, class_name: 'Event', foreign_key: 'creator_id'
  has_many :vendor_events, -> { where(event_participants: { role: :vendor }) },
           through: :event_participants, source: :event
  has_many :categorizations, as: :categorizable, dependent: :destroy
  has_many :interests, through: :categorizations, source: :category

  # Validations
  validates :first_name, :last_name, :phone, :company, presence: true

  # Scopes
  scope :admins,        -> { where.not(role: :attendee) }
  scope :super_admins,  -> { where(role: :super_admin) }
  scope :attendees_only, -> { where(role: :attendee) }
  scope :by_company, ->(company) { where(company: company) }
  scope :text_capable, -> { where(text_capable: true) }
  scope :registered, -> { where.not(registered_at: nil) }
  scope :with_phone, -> { where.not(phone: [nil, '']) }

  # Admin safety validations
  validate :cannot_demote_last_admin
  validate :cannot_self_demote, on: :update

  attr_accessor :editing_self

  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def admin?
    # Any elevated role counts as admin-capable
    !attendee?
  end

  def super_admin?
    role == 'super_admin'
  end

  def can_manage_events?
    super_admin? || event_admin?
  end

  def can_manage_venues?
    super_admin? || venue_admin?
  end

  def can_manage_vendors?
    super_admin? || vendor_admin?
  end

  # Event-specific methods - delegate to event_participants
  def participant_for_event(event)
    # Cache to avoid N+1 queries
    @participants_by_event_id ||= event_participants.index_by(&:event_id)
    @participants_by_event_id[event.id]
  end

  def role_for_event(event)
    participant_for_event(event)&.role || 'attendee'
  end

  def vendor_for_event?(event)
    participant_for_event(event)&.vendor? || false
  end

  def organizer_for_event?(event)
    participant_for_event(event)&.organizer? || false
  end

  def rsvp_status_for_event(event)
    participant_for_event(event)&.rsvp_status || 'pending'
  end

  def checked_in_for_event?(event)
    participant_for_event(event)&.checked_in? || false
  end

  private

  def cannot_demote_last_admin
    if role_changed? && role_was == 'super_admin' && role == 'attendee'
      remaining = User.where(role: :super_admin).where.not(id: id).count
      errors.add(:role, 'Cannot remove the last super admin') if remaining == 0
    end
  end

  def cannot_self_demote
    if @editing_self && role_changed? && role_was == 'super_admin' && role == 'attendee'
      errors.add(:role, 'You cannot remove your own super admin privileges')
    end
  end
end
