require 'rails_helper'

RSpec.describe 'Public Event Guest RSVP', type: :system do
  let(:venue) { create(:venue, name: 'Test Venue', address: '123 Main St') }
  let(:creator) { create(:user) }
  
  let!(:event) do
    create(:event,
           name: 'Cinco de Mayo Party',
           event_date: Date.new(2026, 5, 5),
           start_time: Time.parse('18:00'),
           venue: venue,
           creator: creator,
           slug: 'cinco-de-mayo-party-2026',
           public_rsvp_enabled: true,
           max_attendees: 50)
  end

  before do
    driven_by(:rack_test)
  end

  scenario 'Guest RSVPs to public event without logging in' do
    # Visit public event page
    visit public_event_path(event.slug)

    # Verify event details are displayed
    expect(page).to have_content('Cinco de Mayo Party')
    expect(page).to have_content('Tuesday, May 05, 2026')
    expect(page).to have_content('Test Venue')
    expect(page).to have_content('0 / 50 attending')

    # Fill in guest RSVP form
    fill_in 'Your Name', with: 'Bob Test'
    fill_in 'Email (optional - for updates)', with: 'bob@example.com'
    fill_in 'Phone (optional)', with: '555-1234'
    
    # Select "Yes, I'll be there!"
    choose 'event_participant_rsvp_status_yes'

    # Submit RSVP
    click_button 'Submit RSVP'

    # Should redirect to confirmation page
    expect(page).to have_current_path(public_event_confirmation_path(event.slug, participant_id: EventParticipant.last.id))
    
    # Verify confirmation message
    expect(page).to have_content('Thank You!')
    expect(page).to have_content('Your RSVP has been successfully submitted')
    expect(page).to have_content('Bob Test')
    expect(page).to have_content('bob@example.com')
    expect(page).to have_content('Attending')

    # Verify "Add to Calendar" button appears for "Yes" RSVP
    expect(page).to have_link('Add to Calendar')

    # Verify participant was created correctly
    participant = EventParticipant.last
    expect(participant.guest_name).to eq('Bob Test')
    expect(participant.guest_email).to eq('bob@example.com')
    expect(participant.guest_phone).to eq('555-1234')
    expect(participant.is_guest).to be true
    expect(participant.user_id).to be_nil
    expect(participant.rsvp_status).to eq('yes')
  end

  scenario 'Guest RSVP with minimal info (name only)' do
    visit public_event_path(event.slug)

    fill_in 'Your Name', with: 'Minimal Guest'
    choose 'event_participant_rsvp_status_maybe'

    click_button 'Submit RSVP'

    expect(page).to have_content('Thank You!')
    
    participant = EventParticipant.last
    expect(participant.guest_name).to eq('Minimal Guest')
    expect(participant.guest_email).to be_nil
    expect(participant.rsvp_status).to eq('maybe')
  end

  scenario 'Cannot access event with public RSVP disabled' do
    event.update(public_rsvp_enabled: false)

    visit public_event_path(event.slug)

    expect(page).to have_current_path(root_path)
    expect(page).to have_content('This event does not accept public RSVPs')
  end

  scenario 'Event not found shows error' do
    visit public_event_path('nonexistent-event')

    expect(page).to have_current_path(root_path)
    expect(page).to have_content('Event not found')
  end

  scenario 'Confirmation page has share functionality' do
    participant = create(:event_participant, 
                         event: event, 
                         guest_name: 'Test Guest',
                         is_guest: true,
                         rsvp_status: 'yes')

    visit public_event_confirmation_path(event.slug, participant_id: participant.id)

    # Verify share section exists
    expect(page).to have_content('Spread the Word!')
    expect(page).to have_button('Copy Link')
    
    # Verify social share links exist
    expect(page).to have_link('Facebook', href: /facebook/)
    expect(page).to have_link('Twitter', href: /twitter/)
    expect(page).to have_link('Email', href: /mailto:/)
  end
end
