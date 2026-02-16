require 'rails_helper'

RSpec.describe Event, type: :model do
  let(:venue) { create(:venue) }
  let(:creator) { create(:user) }

  describe 'validations' do
    subject { build(:event) }
    
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:event_date) }
    it { is_expected.to validate_presence_of(:rsvp_deadline) }
    it { is_expected.to validate_presence_of(:max_attendees) }
    it { is_expected.to validate_numericality_of(:max_attendees).is_greater_than(0) }
    it { is_expected.to validate_uniqueness_of(:slug).allow_nil }
  end

  describe 'associations' do
    subject { build(:event) }
    
    it { is_expected.to belong_to(:venue) }
    it { is_expected.to belong_to(:creator).class_name('User') }
    it { is_expected.to have_many(:event_participants) }
    it { is_expected.to have_many(:users).through(:event_participants) }
  end

  describe 'slug generation' do
    it 'generates slug on create' do
      event = create(:event, 
                     name: 'Summer BBQ Party',
                     event_date: Date.new(2026, 7, 4),
                     venue: venue,
                     creator: creator)
      
      expect(event.slug).to eq('summer-bbq-party-2026')
    end

    it 'handles duplicate names by adding counter' do
      event1 = create(:event,
                      name: 'Pool Party',
                      event_date: Date.new(2026, 6, 1),
                      venue: venue,
                      creator: creator)
      
      event2 = create(:event,
                      name: 'Pool Party',
                      event_date: Date.new(2026, 6, 1),
                      venue: venue,
                      creator: creator)
      
      expect(event1.slug).to eq('pool-party-2026')
      expect(event2.slug).to eq('pool-party-2026-2')
    end

    it 'does not overwrite manually set slug' do
      event = create(:event,
                     name: 'Test Event',
                     slug: 'custom-slug',
                     venue: venue,
                     creator: creator)
      
      expect(event.slug).to eq('custom-slug')
    end
  end

  describe '#public_url' do
    it 'returns correct URL with slug' do
      event = create(:event,
                     slug: 'cinco-de-mayo-2026',
                     venue: venue,
                     creator: creator)
      
      expect(event.public_url).to eq('http://localhost:3000/e/cinco-de-mayo-2026')
    end

    it 'returns nil if slug is not set' do
      event = build(:event, slug: nil)
      expect(event.public_url).to be_nil
    end
  end

  describe '#to_param' do
    it 'returns slug if present' do
      event = create(:event, slug: 'test-slug', venue: venue, creator: creator)
      expect(event.to_param).to eq('test-slug')
    end

    it 'returns id if slug is nil' do
      event = create(:event, venue: venue, creator: creator)
      event.update_column(:slug, nil) # Bypass validation
      expect(event.to_param).to eq(event.id)
    end
  end
end
