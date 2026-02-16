# RSpec Test Suite for Embeddable Link Feature

## What I Created:

### 1. Controller Tests (`spec/controllers/public_events_controller_spec.rb`)
Tests for the PublicEventsController:
- ✅ Public event page displays correctly
- ✅ Private events redirect properly
- ✅ Guest RSVP creation works
- ✅ Logged-in user RSVP works
- ✅ Updates existing RSVPs instead of creating duplicates
- ✅ Confirmation page displays
- ✅ Calendar .ics download works

### 2. Model Tests (`spec/models/event_spec.rb`)
Tests for Event model new features:
- ✅ Slug generation on create
- ✅ Handles duplicate event names
- ✅ Slug uniqueness validation
- ✅ Public URL generation
- ✅ to_param returns slug

### 3. Model Tests (`spec/models/event_participant_spec.rb`)
Tests for EventParticipant guest functionality:
- ✅ Guest validation (requires guest_name)
- ✅ Email format validation
- ✅ User vs guest requirement
- ✅ display_name, display_email, display_phone methods

### 4. System Tests (`spec/system/public_event_rsvp_spec.rb`)
End-to-end integration tests:
- ✅ Full guest RSVP flow (visit → fill form → submit → confirmation)
- ✅ Minimal guest RSVP (name only)
- ✅ Private event access denied
- ✅ Event not found handling
- ✅ Share functionality on confirmation page

### 5. Updated Factories
- ✅ Event factory now has `:public` trait and `public_rsvp_enabled`
- ✅ EventParticipant factory now has `:guest` trait

## How to Run Tests:

### Run All Tests
```bash
bundle exec rspec
```

### Run Specific Test Files
```bash
# Controller tests only
bundle exec rspec spec/controllers/public_events_controller_spec.rb

# Model tests only
bundle exec rspec spec/models/event_spec.rb
bundle exec rspec spec/models/event_participant_spec.rb

# System tests only (full integration)
bundle exec rspec spec/system/public_event_rsvp_spec.rb
```

### Run Tests with Documentation Format
```bash
bundle exec rspec --format documentation
```

### Run Tests and Generate Coverage Report
```bash
bundle exec rspec --format documentation --format html --out spec_results.html
```

## Expected Results:

If everything is working correctly, you should see:

```
PublicEventsController
  GET #show
    when event has public RSVP enabled
      displays the public event page
    when event does not have public RSVP enabled
      redirects to root with alert
    when event does not exist
      redirects to root with alert
  POST #rsvp
    guest RSVP (not logged in)
      creates a new guest RSVP
      redirects to confirmation page
    logged in user RSVP
      creates RSVP associated with user
      updates existing RSVP instead of creating duplicate
  GET #confirmation
    displays confirmation page
    redirects if participant not found
  GET #calendar
    generates .ics file for download

Event
  slug generation
    generates slug on create
    handles duplicate names by adding counter
    does not overwrite manually set slug
  #public_url
    returns correct URL with slug
    returns nil if slug is not set
  #to_param
    returns slug if present
    returns id if slug is nil

EventParticipant
  validations
    guest participant
      should validate that :guest_name cannot be empty/falsy
      allows guest_email to be blank
      validates guest_email format when present
      is valid with name only
    registered user participant
      does not require guest_name
    requires either user or guest info
  #display_name
    returns guest_name for guest participants
    returns user full_name for registered participants
  #display_email
    returns guest_email for guest participants
    returns user email for registered participants
  #display_phone
    returns guest_phone for guest participants
    returns user phone for registered participants

Public Event Guest RSVP
  Guest RSVPs to public event without logging in
  Guest RSVP with minimal info (name only)
  Cannot access event with public RSVP disabled
  Event not found shows error
  Confirmation page has share functionality

Finished in X.XX seconds (files took X.XX seconds to load)
XX examples, 0 failures
```

## Debugging Failed Tests:

If tests fail, common issues:

1. **Database not migrated in test environment:**
   ```bash
   RAILS_ENV=test bundle exec rails db:migrate
   ```

2. **Need to reset test database:**
   ```bash
   RAILS_ENV=test bundle exec rails db:reset
   ```

3. **Missing gems:**
   ```bash
   bundle install
   ```

4. **Factories need updating:**
   - Check `spec/factories/` files match your models

## Test Coverage:

These tests cover:
- ✅ Happy path (everything works)
- ✅ Edge cases (missing data, invalid data)
- ✅ Access control (public vs private events)
- ✅ Guest vs authenticated user flows
- ✅ Full integration (system tests)

## Next Steps:

After tests pass, consider adding:
- Performance tests (load testing with many RSVPs)
- Email delivery tests (if you add confirmation emails)
- JavaScript/AJAX tests (if you add dynamic features)
- API tests (if you expose public RSVP via API)

---

**Quick Start:**
```bash
# Make sure test database is ready
RAILS_ENV=test bundle exec rails db:migrate

# Run all new tests
bundle exec rspec spec/controllers/public_events_controller_spec.rb \
                  spec/models/event_spec.rb \
                  spec/models/event_participant_spec.rb \
                  spec/system/public_event_rsvp_spec.rb
```
