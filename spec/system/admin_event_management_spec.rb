require 'rails_helper'

RSpec.describe 'Admin Event Management', type: :system do
  let!(:admin_user) { create(:user, :admin) }
  let!(:venue) { create(:venue) }
  let!(:attendee_users) { create_list(:user, 3) }

  before do
    driven_by(:selenium_chrome_headless)
    login_as(admin_user, scope: :user)
  end

  # Chrome datetime-local and time inputs require JS in headless mode.
  # The event form has a duplicate event[event_date] field (hosted + reference sections);
  # we must set ALL inputs with a given name to avoid the hidden empty one overriding.
  def set_all_inputs(field_name, value)
    page.execute_script(
      "document.querySelectorAll('input[name=\"#{field_name}\"]').forEach(el => el.value = '#{value}')"
    )
  end

  describe 'Event Creation' do
    it 'creates a basic event successfully' do
      visit admin_events_path
      click_link 'New Event'

      fill_in 'Name', with: 'Annual Company Retreat'
      fill_in 'Description', with: 'Our yearly team building event'
      select venue.name, from: 'Venue'
      fill_in 'Max attendees', with: '100'

      event_date    = 1.week.from_now
      rsvp_deadline = event_date - 3.days
      set_all_inputs('event[event_date]',    event_date.strftime('%Y-%m-%dT%H:%M'))
      set_all_inputs('event[rsvp_deadline]', rsvp_deadline.strftime('%Y-%m-%dT%H:%M'))
      set_all_inputs('event[start_time]',    '09:00')
      set_all_inputs('event[end_time]',      '17:00')

      click_button 'Create Event'

      expect(page).to have_content 'Event created successfully'
      expect(page).to have_content 'Annual Company Retreat'
      expect(page).to have_content venue.name
    end

    it 'creates an event with custom questions' do
      visit new_admin_event_path

      fill_in 'Name', with: 'Conference with Questions'
      fill_in 'Description', with: 'Event requiring additional information'
      select venue.name, from: 'Venue'
      fill_in 'Max attendees', with: '50'

      event_date = 2.weeks.from_now
      set_all_inputs('event[event_date]',    event_date.strftime('%Y-%m-%dT%H:%M'))
      set_all_inputs('event[rsvp_deadline]', (event_date - 1.week).strftime('%Y-%m-%dT%H:%M'))
      set_all_inputs('event[start_time]',    '10:00')
      set_all_inputs('event[end_time]',      '16:00')

      click_button 'Add Question'
      within first('.custom-question-row') do
        fill_in 'event[custom_questions][]', with: 'Any dietary restrictions?'
      end

      click_button 'Add Question'
      within all('.custom-question-row').last do
        fill_in 'event[custom_questions][]', with: 'What is your t-shirt size?'
      end

      click_button 'Create Event'

      expect(page).to have_content 'Event created successfully'
      expect(page).to have_content 'Any dietary restrictions?'
      expect(page).to have_content 'What is your t-shirt size?'
    end

    it 'validates required fields' do
      visit new_admin_event_path

      # Remove HTML5 required attributes so browser validation doesn't block submission;
      # this exercises Rails server-side validation
      page.execute_script("document.querySelectorAll('[required]').forEach(el => el.removeAttribute('required'))")
      click_button 'Create Event'

      expect(page).to have_content 'prohibited this event from being saved'
    end
  end

  describe 'Event Editing' do
    let!(:event) { create(:event, venue: venue, creator: admin_user, custom_questions: ['Original question']) }

    it 'edits event basic information' do
      visit edit_admin_event_path(event)

      fill_in 'Name', with: 'Updated Event Name'
      fill_in 'Description', with: 'Updated description'
      fill_in 'Max attendees', with: '200'

      click_button 'Update Event'

      expect(page).to have_content 'Event updated successfully'
      expect(page).to have_content 'Updated Event Name'
    end

    it 'manages custom questions dynamically' do
      visit edit_admin_event_path(event)

      within first('.custom-question-row') do
        click_button 'Remove'
      end

      click_button 'Add Question'
      within first('.custom-question-row') do
        fill_in 'event[custom_questions][]', with: 'New question 1'
      end

      click_button 'Add Question'
      within all('.custom-question-row').last do
        fill_in 'event[custom_questions][]', with: 'New question 2'
      end

      click_button 'Update Event'

      expect(page).to have_content 'Event updated successfully'
      expect(page).to have_content 'New question 1'
      expect(page).to have_content 'New question 2'
      expect(page).not_to have_content 'Original question'
    end
  end

  describe 'Participant Management' do
    let!(:event) { create(:event, venue: venue, creator: admin_user) }

    it 'adds participants to an event' do
      visit participants_admin_event_path(event)

      # collection_select has no label; reference by input id
      select "#{attendee_users.first.first_name} #{attendee_users.first.last_name} (#{attendee_users.first.email})",
             from: 'event_participant_user_id'
      click_button 'Add Participant'

      expect(page).to have_content 'Participant added successfully'
      expect(page).to have_content attendee_users.first.email
    end

    # NOTE: remove_participant action is not yet implemented in Admin::EventsController
    # The route exists (DELETE /admin/events/:id/remove_participant) but the action is missing.
    # This test is pending until the action is implemented.
    xit 'removes participants from an event' do
      event.event_participants.create!(user: attendee_users.first, role: 'attendee')

      visit participants_admin_event_path(event)
      expect(page).to have_content attendee_users.first.email

      click_button 'Remove'

      expect(page).to have_content 'Participant removed successfully'
      expect(page).not_to have_content attendee_users.first.email
    end

    it 'exports participant list as CSV' do
      event.event_participants.create!(user: attendee_users.first, role: 'attendee', rsvp_status: 'yes')
      event.event_participants.create!(user: attendee_users.second, role: 'vendor', rsvp_status: 'maybe')

      visit participants_admin_event_path(event)

      # Verify the Export CSV link is present and points to a .csv route
      # (page.response_headers is rack_test only; Selenium can only check link presence)
      expect(page).to have_link('Export CSV')
      expect(find_link('Export CSV')[:href]).to include('.csv')
    end
  end

  describe 'Event Navigation' do
    let!(:events) { create_list(:event, 3, venue: venue, creator: admin_user) }

    it 'navigates between event management sections' do
      event = events.first
      visit admin_events_path

      # Go to event show page
      click_link event.name
      expect(page).to have_content event.description

      # Go to participants page from show (sidebar link)
      click_link 'Manage Participants'
      expect(page).to have_content "#{event.name} - Participants"

      # Return to event show
      click_link 'Back to Event'
      expect(page).to have_content event.name

      # Go to edit page from show — two "Edit Event" links exist; use match: :first
      click_link 'Edit Event', match: :first
      expect(page).to have_field 'Name', with: event.name
    end
  end
end
