require 'rails_helper'

RSpec.describe ConOptIn, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:event) }
    it { is_expected.to belong_to(:vendor_event) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:vendor_opt_ins).dependent(:destroy) }
    it { is_expected.to have_many(:vendor_events).through(:vendor_opt_ins) }
    it { is_expected.to have_many(:broadcast_receipts).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:con_opt_in) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:event_id) }
    it { is_expected.to validate_presence_of(:vendor_event_id) }

    it 'validates uniqueness of phone scoped to event' do
      existing = create(:con_opt_in, phone: '+15035550001')
      duplicate = build(:con_opt_in, phone: '+15035550001', event: existing.event)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:phone]).to be_present
    end

    it 'allows same phone for different events' do
      event1 = create(:event)
      event2 = create(:event)
      ve1 = create(:vendor_event, event: event1)
      ve2 = create(:vendor_event, event: event2)

      create(:con_opt_in, phone: '+15035550001', event: event1, vendor_event: ve1)
      opt_in2 = build(:con_opt_in, phone: '+15035550001', event: event2, vendor_event: ve2)
      expect(opt_in2).to be_valid
    end

    it 'is invalid without phone or email' do
      opt_in = build(:con_opt_in, phone: nil, email: nil)
      expect(opt_in).not_to be_valid
      expect(opt_in.errors[:base]).to include('Please provide a phone number or email address')
    end

    it 'is valid with only email' do
      # build leaves associations unpersisted (no IDs), so use create
      opt_in = create(:con_opt_in, :email_only)
      expect(opt_in).to be_valid
    end

    it 'validates email format' do
      opt_in = build(:con_opt_in, :email_only, email: 'not-an-email')
      expect(opt_in).not_to be_valid
      expect(opt_in.errors[:email]).to be_present
    end
  end

  describe '#opted_in_at auto-set' do
    it 'sets opted_in_at on create if not provided' do
      opt_in = create(:con_opt_in)
      expect(opt_in.opted_in_at).to be_present
    end

    it 'does not overwrite an existing opted_in_at' do
      time = 2.hours.ago
      opt_in = create(:con_opt_in, opted_in_at: time)
      expect(opt_in.opted_in_at).to be_within(1.second).of(time)
    end
  end

  describe '#display_contact' do
    it 'returns phone when present' do
      opt_in = build(:con_opt_in, phone: '+15035551234', email: nil)
      expect(opt_in.display_contact).to eq('+15035551234')
    end

    it 'falls back to email when no phone' do
      opt_in = build(:con_opt_in, :email_only, email: 'test@example.com')
      expect(opt_in.display_contact).to eq('test@example.com')
    end

    it 'returns fallback string when no contact info' do
      opt_in = build(:con_opt_in)
      opt_in.phone = nil
      opt_in.email = nil
      expect(opt_in.display_contact).to eq('No contact info')
    end
  end
end
