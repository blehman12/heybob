# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # ONLY role belongs on User - it's a system-wide permission level
  enum role: { attendee: 0, admin: 1 }

  # Associations
  has_many :event_participants, dependent: :destroy
  has_many :events, through: :event_participants
  has_many :created_events, class_name: 'Event', foreign_key: 'creator_id'
  has_many :vendor_events, -> { where(event_participants: { role: :vendor }) }, 
           through: :event_participants, source: :event

  # Validations
  validates :first_name, :last_name, :phone, :company, presence: true

  # Scopes
  scope :admins, -> { where(role: :admin) }
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
    role == 'admin'
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
    if role_changed? && role_was == 'admin' && role != 'admin'
      remaining_admins = User.where(role: 'admin').where.not(id: id).count
      if remaining_admins == 0
        errors.add(:role, 'Cannot remove the last admin user')
      end
    end
  end

  def cannot_self_demote
    if @editing_self && role_changed? && role_was == 'admin' && role != 'admin'
      errors.add(:role, 'You cannot remove your own admin privileges')
    end
  end
end
