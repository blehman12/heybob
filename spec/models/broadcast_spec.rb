require 'rails_helper'

RSpec.describe Broadcast, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:vendor_event) }
    it { is_expected.to have_many(:broadcast_receipts).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:broadcast) }

    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_presence_of(:channel) }
    # Custom error message prevents shoulda-matchers length test from working;
    # tested explicitly below instead.

    it 'is invalid when message exceeds 160 characters' do
      broadcast = build(:broadcast, message: 'A' * 161)
      expect(broadcast).not_to be_valid
      expect(broadcast.errors[:message]).to include(match(/160 characters/i))
    end

    it 'is valid with exactly 160 characters' do
      broadcast = build(:broadcast, :long_message)
      expect(broadcast).to be_valid
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:channel).with_values(sms: 0, email: 1, feed: 2) }
    it { is_expected.to define_enum_for(:scope).with_values(booth_visitors: 0, entire_con: 1) }
  end

  describe 'scopes' do
    let!(:sent_broadcast)    { create(:broadcast, :sent) }
    let!(:pending_broadcast) { create(:broadcast, :pending) }

    it '.sent returns broadcasts with sent_at set' do
      expect(Broadcast.sent).to include(sent_broadcast)
      expect(Broadcast.sent).not_to include(pending_broadcast)
    end

    it '.pending returns broadcasts without sent_at' do
      expect(Broadcast.pending).to include(pending_broadcast)
      expect(Broadcast.pending).not_to include(sent_broadcast)
    end

    it '.recent orders by sent_at descending' do
      older = create(:broadcast, :sent, sent_at: 3.hours.ago,
                     vendor_event: sent_broadcast.vendor_event)
      results = Broadcast.sent.recent
      expect(results.first.sent_at).to be >= results.last.sent_at
    end
  end

  describe '#sent?' do
    it 'returns true when sent_at is present' do
      expect(build(:broadcast, :sent).sent?).to be true
    end

    it 'returns false when sent_at is nil' do
      expect(build(:broadcast, :pending).sent?).to be false
    end
  end

  describe '#recipients' do
    let(:event)        { create(:event) }
    let(:vendor)       { create(:vendor) }
    let(:vendor_event) { create(:vendor_event, vendor: vendor, event: event) }
    let(:other_ve)     { create(:vendor_event, event: event) }

    let!(:booth_opt_in) do
      opt_in = create(:con_opt_in, event: event, vendor_event: vendor_event,
                      phone: '+15035550001')
      VendorOptIn.create!(vendor_event: vendor_event, con_opt_in: opt_in,
                          scanned_at: Time.current)
      opt_in
    end

    let!(:other_opt_in) do
      create(:con_opt_in, event: event, vendor_event: other_ve,
             phone: '+15035550002')
    end

    context 'booth_visitors scope' do
      let(:broadcast) { create(:broadcast, vendor_event: vendor_event) }

      it 'returns only this vendor\'s opt-ins' do
        expect(broadcast.recipients).to include(booth_opt_in)
        expect(broadcast.recipients).not_to include(other_opt_in)
      end
    end

    context 'entire_con scope' do
      let(:broadcast) { create(:broadcast, :entire_con, vendor_event: vendor_event) }

      it 'returns all opt-ins for the event' do
        expect(broadcast.recipients).to include(booth_opt_in)
        expect(broadcast.recipients).to include(other_opt_in)
      end
    end
  end
end
