require 'rails_helper'

RSpec.describe Vendor, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:vendor_users).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:vendor_users) }
    it { is_expected.to have_many(:vendor_events).dependent(:destroy) }
    it { is_expected.to have_many(:events).through(:vendor_events) }
  end

  describe 'validations' do
    subject { build(:vendor) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:user) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:participant_type).with_values(business: 0, artist: 1) }
  end

  describe '#accessible_by?' do
    let(:owner)       { create(:user) }
    let(:other_user)  { create(:user) }
    let(:vendor)      { create(:vendor, user: owner) }

    it 'is accessible by the owner' do
      expect(vendor.accessible_by?(owner)).to be true
    end

    it 'is not accessible by a random user' do
      expect(vendor.accessible_by?(other_user)).to be false
    end

    it 'is accessible by a VendorUser (shared access)' do
      vendor.vendor_users.create!(user: other_user)
      expect(vendor.accessible_by?(other_user)).to be true
    end
  end

  describe '#artist?' do
    it 'returns true for artist type' do
      expect(build(:vendor, :artist).artist?).to be true
    end

    it 'returns false for business type' do
      expect(build(:vendor).artist?).to be false
    end
  end

  describe '#social_handles' do
    it 'returns only present handles' do
      vendor = build(:vendor, instagram_handle: '@insta', twitter_handle: nil, tiktok_handle: nil)
      expect(vendor.social_handles).to eq({ instagram: '@insta' })
    end

    it 'returns empty hash when no handles set' do
      vendor = build(:vendor, instagram_handle: nil, twitter_handle: nil, tiktok_handle: nil)
      expect(vendor.social_handles).to be_empty
    end
  end

  describe '#primary_web_presence' do
    context 'business vendor' do
      it 'returns website' do
        vendor = build(:vendor, website: 'https://example.com')
        expect(vendor.primary_web_presence).to eq('https://example.com')
      end
    end

    context 'artist vendor' do
      it 'returns first social handle when no website' do
        vendor = build(:vendor, :artist, :with_social, website: nil)
        expect(vendor.primary_web_presence).to be_present
      end

      it 'returns website when present' do
        vendor = build(:vendor, :artist, website: 'https://art.example.com')
        expect(vendor.primary_web_presence).to eq('https://art.example.com')
      end
    end
  end
end
