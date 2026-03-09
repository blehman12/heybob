require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }
    
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:phone) }
    it { is_expected.to validate_presence_of(:company) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end
  
  describe 'enums' do
    it do
      is_expected.to define_enum_for(:role).with_values(
        attendee: 0, super_admin: 1, event_admin: 2, venue_admin: 3, vendor_admin: 4
      )
    end
  end
  
  describe '#full_name' do
    it 'returns the full name' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end
  
  describe 'admin functionality' do
    let(:admin) { create(:user, :admin) }
    let(:regular_user) { create(:user) }
    
    it 'identifies admin users correctly' do
      expect(admin.admin?).to be true
      expect(regular_user.admin?).to be false
    end
  end
end