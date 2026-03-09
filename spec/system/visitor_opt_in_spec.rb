require 'rails_helper'

RSpec.describe 'Visitor QR Opt-in Flow', type: :system do
  before { driven_by(:rack_test) }

  let(:owner)        { create(:user) }
  let(:vendor)       { create(:vendor, user: owner, name: 'Pixel Arts') }
  let(:event)        { create(:event, name: 'Sakuracon 2026') }
  let(:vendor_event) { create(:vendor_event, :artist_alley, vendor: vendor, event: event) }

  describe 'opt-in landing page (GET /join/:qr_token)' do
    it 'shows the vendor-branded opt-in page' do
      visit vendor_optin_path(vendor_event.qr_token)

      expect(page).to have_content('Pixel Arts')
      expect(page).to have_field('Name')
    end

    it 'shows 404 message for invalid QR token' do
      visit vendor_optin_path('invalid-token-xyz')

      expect(page.status_code).to eq(404)
    end
  end

  describe 'submitting the opt-in form (POST /join/:qr_token)' do
    it 'creates a ConOptIn and redirects to welcome page' do
      visit vendor_optin_path(vendor_event.qr_token)

      fill_in 'Name', with: 'Alice Fan'
      fill_in 'Phone', with: '+15035550100'

      click_button 'Count Me In'

      expect(page).to have_current_path(vendor_optin_welcome_path(vendor_event.qr_token))

      opt_in = ConOptIn.last
      expect(opt_in.name).to eq('Alice Fan')
      expect(opt_in.phone).to eq('+15035550100')
      expect(opt_in.event).to eq(event)
      expect(opt_in.vendor_event).to eq(vendor_event)
      expect(opt_in.opted_in_at).to be_present
    end

    it 'creates a VendorOptIn join record' do
      visit vendor_optin_path(vendor_event.qr_token)
      fill_in 'Name', with: 'Bob Fan'
      fill_in 'Phone', with: '+15035550101'
      click_button 'Count Me In'

      expect(VendorOptIn.count).to eq(1)
      expect(VendorOptIn.last.vendor_event).to eq(vendor_event)
    end

    it 'handles duplicate opt-in gracefully (same phone same event)' do
      create(:con_opt_in, phone: '+15035550200', name: 'First Visit',
             event: event, vendor_event: vendor_event)

      visit vendor_optin_path(vendor_event.qr_token)
      fill_in 'Name', with: 'Return Visitor'
      fill_in 'Phone', with: '+15035550200'
      click_button 'Count Me In'

      expect(page).to have_current_path(vendor_optin_welcome_path(vendor_event.qr_token))
      # Should not create a second ConOptIn
      expect(ConOptIn.count).to eq(1)
    end

    it 'shows error when neither phone nor email is provided' do
      visit vendor_optin_path(vendor_event.qr_token)
      fill_in 'Name', with: 'No Contact'
      click_button 'Count Me In'

      expect(page).to have_content('phone number or email')
      expect(ConOptIn.count).to eq(0)
    end
  end

  describe 'welcome page (GET /join/:qr_token/welcome)' do
    it 'displays after successful opt-in' do
      visit vendor_optin_welcome_path(vendor_event.qr_token)

      expect(page).to have_content('Pixel Arts')
    end
  end

  describe 'event feed page (GET /feed/:event_slug)' do
    it 'shows the event feed' do
      visit event_feed_path(event.slug)

      expect(page.status_code).to eq(200)
    end

    it 'shows sent broadcasts on the feed' do
      broadcast = create(:broadcast, :sent, vendor_event: vendor_event,
                         message: 'Big sale at table A-12!')
      visit event_feed_path(event.slug)

      expect(page).to have_content('Big sale at table A-12!')
    end

    it 'does not show unsent (pending) broadcasts' do
      create(:broadcast, :pending, vendor_event: vendor_event,
             message: 'This is a draft message')
      visit event_feed_path(event.slug)

      expect(page).not_to have_content('This is a draft message')
    end

    it 'returns 404 for unknown event slug' do
      visit event_feed_path('nonexistent-event-2099')
      expect(page.status_code).to eq(404)
    end
  end
end
