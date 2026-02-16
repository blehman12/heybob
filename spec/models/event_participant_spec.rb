require 'rails_helper'

RSpec.describe EventParticipant, type: :model do
  let(:event) { create(:event) }
  let(:user) { create(:user) }

  describe 'validations' do
    context 'guest participant' do
      subject { build(:event_participant, is_guest: true, user: nil, guest_name: 'John Doe') }

      it { is_expected.to validate_presence_of(:guest_name) }
      
      it 'allows guest_email to be blank' do
        participant = build(:event_participant, is_guest: true, user: nil, guest_name: 'John', guest_email: '')
        expect(participant).to be_valid
      end

      it 'validates guest_email format when present' do
        participant = build(:event_participant, is_guest: true, user: nil, guest_name: 'John', guest_email: 'invalid')
        expect(participant).not_to be_valid
        expect(participant.errors[:guest_email]).to be_present
      end

      it 'is valid with name only' do
        participant = build(:event_participant, is_guest: true, user: nil, guest_name: 'John Doe')
        expect(participant).to be_valid
      end
    end

    context 'registered user participant' do
      it 'does not require guest_name' do
        participant = build(:event_participant, user: user, event: event, is_guest: false)
        expect(participant).to be_valid
      end
    end

    it 'requires either user or guest info' do
      participant = build(:event_participant, user: nil, guest_name: nil, event: event)
      expect(participant).not_to be_valid
      expect(participant.errors[:base]).to include('Must have either a user account or guest information')
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:event) }
    it { is_expected.to belong_to(:user).optional }
  end

  describe '#display_name' do
    it 'returns guest_name for guest participants' do
      participant = build(:event_participant, is_guest: true, guest_name: 'Jane Smith', user: nil)
      expect(participant.display_name).to eq('Jane Smith')
    end

    it 'returns user full_name for registered participants' do
      participant = build(:event_participant, is_guest: false, user: user)
      expect(participant.display_name).to eq(user.full_name)
    end
  end

  describe '#display_email' do
    it 'returns guest_email for guest participants' do
      participant = build(:event_participant, is_guest: true, user: nil, guest_name: 'John', guest_email: 'john@example.com')
      expect(participant.display_email).to eq('john@example.com')
    end

    it 'returns user email for registered participants' do
      participant = build(:event_participant, is_guest: false, user: user)
      expect(participant.display_email).to eq(user.email)
    end
  end

  describe '#display_phone' do
    it 'returns guest_phone for guest participants' do
      participant = build(:event_participant, is_guest: true, user: nil, guest_name: 'John', guest_phone: '555-1234')
      expect(participant.display_phone).to eq('555-1234')
    end

    it 'returns user phone for registered participants' do
      participant = build(:event_participant, is_guest: false, user: user)
      expect(participant.display_phone).to eq(user.phone)
    end
  end
end
