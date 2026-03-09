require 'rails_helper'

RSpec.describe VendorEvent, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:vendor) }
    it { is_expected.to belong_to(:event) }
    it { is_expected.to have_many(:vendor_opt_ins).dependent(:destroy) }
    it { is_expected.to have_many(:con_opt_ins).through(:vendor_opt_ins) }
    it { is_expected.to have_many(:broadcasts).dependent(:destroy) }
  end

  describe 'validations' do
    # qr_token is auto-generated; shoulda-matchers needs a persisted subject
    # with a valid token already set so DB NOT NULL constraint doesn't blow up.
    subject { create(:vendor_event) }

    it { is_expected.to validate_uniqueness_of(:vendor_id).scoped_to(:event_id) }
    it { is_expected.to validate_uniqueness_of(:qr_token) }

    it 'always has a qr_token after create' do
      expect(subject.qr_token).to be_present
    end
  end

  describe 'enums' do
    it do
      is_expected.to define_enum_for(:category).with_values(
        dealer: 0, artist_alley: 1, sponsor: 2, exhibitor: 3, panelist: 4
      )
    end
  end

  describe 'qr_token generation' do
    it 'auto-generates a qr_token before create' do
      vendor_event = create(:vendor_event)
      expect(vendor_event.qr_token).to be_present
    end

    it 'does not overwrite an existing qr_token' do
      vendor_event = build(:vendor_event)
      vendor_event.qr_token = 'my-custom-token'
      vendor_event.save!
      expect(vendor_event.qr_token).to eq('my-custom-token')
    end

    it 'generates unique tokens for each record' do
      ve1 = create(:vendor_event)
      ve2 = create(:vendor_event)
      expect(ve1.qr_token).not_to eq(ve2.qr_token)
    end
  end

  describe '#booth_number and #hall' do
    it 'extracts booth_number from metadata' do
      ve = build(:vendor_event, :with_booth)
      expect(ve.booth_number).to eq('A-12')
    end

    it 'extracts hall from metadata' do
      ve = build(:vendor_event, :with_booth)
      expect(ve.hall).to eq('Main Hall')
    end

    it 'returns nil when metadata is blank' do
      ve = build(:vendor_event, metadata: nil)
      expect(ve.booth_number).to be_nil
      expect(ve.hall).to be_nil
    end
  end

  describe '#category_label' do
    it 'returns human-friendly label for dealer' do
      expect(build(:vendor_event, category: 'dealer').category_label).to eq("Dealer's Room")
    end

    it 'returns human-friendly label for artist_alley' do
      expect(build(:vendor_event, category: 'artist_alley').category_label).to eq('Artist Alley')
    end

    it 'returns human-friendly label for sponsor' do
      expect(build(:vendor_event, category: 'sponsor').category_label).to eq('Sponsor')
    end
  end

  describe '#optin_headline' do
    let(:vendor) { create(:vendor, name: 'Cool Arts') }
    let(:event)  { create(:event) }

    it 'includes vendor name for artist_alley' do
      ve = build(:vendor_event, :artist_alley, vendor: vendor, event: event)
      expect(ve.optin_headline).to include('Cool Arts')
      expect(ve.optin_headline).to include('art updates')
    end

    it 'includes vendor name for dealer' do
      ve = build(:vendor_event, vendor: vendor, event: event)
      expect(ve.optin_headline).to include('Cool Arts')
      expect(ve.optin_headline).to include('deals')
    end
  end

  describe '#opt_in_count' do
    it 'returns 0 with no opt-ins' do
      ve = create(:vendor_event)
      expect(ve.opt_in_count).to eq(0)
    end

    it 'counts associated con_opt_ins' do
      ve = create(:vendor_event)
      opt1 = create(:con_opt_in, vendor_event: ve, event: ve.event,
                    phone: '+15035550001')
      opt2 = create(:con_opt_in, vendor_event: ve, event: ve.event,
                    phone: '+15035550002')
      # opt_in_count goes through vendor_opt_ins join table
      VendorOptIn.create!(vendor_event: ve, con_opt_in: opt1, scanned_at: Time.current)
      VendorOptIn.create!(vendor_event: ve, con_opt_in: opt2, scanned_at: Time.current)
      expect(ve.opt_in_count).to eq(2)
    end
  end
end
