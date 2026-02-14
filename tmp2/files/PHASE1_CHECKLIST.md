# PHASE 1 IMPLEMENTATION CHECKLIST
# Complete this in order - estimated 14 hours total

## PREPARATION (30 minutes)

- [ ] Backup your database
  ```bash
  # Development database
  cp storage/development.sqlite3 storage/development.sqlite3.backup
  
  # If using PostgreSQL
  pg_dump confab_development > backup_$(date +%Y%m%d).sql
  ```

- [ ] Create a new git branch
  ```bash
  git checkout -b phase1-rsvp-fix-and-sidekiq
  git status  # Make sure working directory is clean
  ```

- [ ] Commit current state
  ```bash
  git add -A
  git commit -m "Pre-Phase 1 checkpoint"
  ```

## PART 1: FIX RSVP DATA MODEL (6 hours)

### Step 1.1: Create the migration (30 min)

- [ ] Copy migration file to your project
  ```bash
  # Copy the file I created:
  # 20260211_fix_rsvp_data_model.rb
  # to: db/migrate/
  
  # Rename with current timestamp
  mv db/migrate/20260211_fix_rsvp_data_model.rb \
     db/migrate/$(date +%Y%m%d%H%M%S)_fix_rsvp_data_model.rb
  ```

- [ ] Review the migration code
  - Understand what it's removing (users.rsvp_status, invited_at, calendar_exported)
  - Note the safety checks
  - Verify rollback plan

- [ ] Test migration in development
  ```bash
  rails db:migrate
  
  # If it works, great!
  # If errors, rollback and fix:
  rails db:rollback
  ```

### Step 1.2: Update User model (1 hour)

- [ ] Replace app/models/user.rb with the fixed version
  - Copy user_model_fixed.rb content
  - Remove rsvp_status enum
  - Keep role enum
  - Update methods to delegate to event_participants

- [ ] Run tests to check for breakage
  ```bash
  bundle exec rspec spec/models/user_spec.rb
  ```

- [ ] Fix any failing tests
  - Update specs that reference user.rsvp_status
  - Change to participant.rsvp_status

### Step 1.3: Update Admin::EventsController (2 hours)

- [ ] Replace app/controllers/admin/events_controller.rb
  - Copy events_controller_fixed.rb content
  - Note changes in show action (lines 14-26)
  - Note changes in participants action
  - Note changes in export_participants

- [ ] Test the admin interface manually
  ```bash
  rails server
  # Login as admin
  # Go to /admin/events
  # Check event show page
  # Verify participant counts display correctly
  ```

### Step 1.4: Update views (1.5 hours)

- [ ] Search for user.rsvp_status in views
  ```bash
  grep -r "user.rsvp_status" app/views/
  ```

- [ ] Replace with participant.rsvp_status
  - In admin/events/show.html.erb
  - In admin/events/participants.html.erb
  - In any dashboards or reports

- [ ] Test all views that display RSVP status
  - Admin event show page
  - Admin participants list
  - User dashboard (if shows events)

### Step 1.5: Run full test suite (1 hour)

- [ ] Fix failing specs
  ```bash
  bundle exec rspec
  
  # Focus on failures one at a time:
  bundle exec rspec spec/path/to/failing_spec.rb:LINE_NUMBER
  ```

- [ ] Update factories if needed
  ```ruby
  # In spec/factories/users.rb - remove rsvp_status if present
  
  # In spec/factories/event_participants.rb - ensure rsvp_status there
  factory :event_participant do
    association :user
    association :event
    role { :attendee }
    rsvp_status { :pending }  # Ensure this is here
  end
  ```

- [ ] Commit your changes
  ```bash
  git add -A
  git commit -m "Fix RSVP data model - remove from users, fix queries"
  ```

## PART 2: ADD SIDEKIQ (4 hours)

### Step 2.1: Install Sidekiq (30 min)

- [ ] Add to Gemfile
  ```ruby
  gem 'sidekiq', '~> 7.2'
  ```

- [ ] Bundle install
  ```bash
  bundle install
  ```

- [ ] Configure Rails to use Sidekiq
  ```ruby
  # config/application.rb - add inside Application class:
  config.active_job.queue_adapter = :sidekiq
  ```

### Step 2.2: Configure Sidekiq (1 hour)

- [ ] Create config/sidekiq.yml
  - Copy content from SIDEKIQ_SETUP.md

- [ ] Create config/initializers/sidekiq.rb
  - Copy Redis configuration from SIDEKIQ_SETUP.md

- [ ] Add Sidekiq routes
  ```ruby
  # config/routes.rb - inside admin namespace:
  require 'sidekiq/web'
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
  ```

- [ ] Test Sidekiq boots
  ```bash
  bundle exec sidekiq -C config/sidekiq.yml
  # Should start without errors
  # Ctrl+C to stop
  ```

### Step 2.3: Update Mailers (1.5 hours)

- [ ] Replace app/mailers/invitation_mailer.rb
  - Copy invitation_mailer.rb I created
  - Update email addresses in default from

- [ ] Create email views
  ```bash
  mkdir -p app/views/invitation_mailer
  ```
  
- [ ] Copy email templates
  - event_invitation.html.erb
  - Create event_invitation.text.erb (plain text version)
  
- [ ] Update existing mailers to use deliver_later
  ```bash
  # Find all deliver_now calls:
  grep -r "deliver_now" app/
  
  # Change to:
  deliver_later(queue: :mailers)
  ```

### Step 2.4: Update Controllers to send emails (1 hour)

- [ ] In Admin::EventsController#bulk_invite
  ```ruby
  # Line 87 - uncomment and update:
  InvitationMailer.event_invitation(participant).deliver_later
  ```

- [ ] In RsvpController (create if missing)
  ```ruby
  def update
    # After successful RSVP update:
    EventNotificationMailer.rsvp_confirmation(@participant).deliver_later
  end
  ```

- [ ] Test email sending
  ```bash
  # Terminal 1: Start Rails
  rails server
  
  # Terminal 2: Start Sidekiq
  bundle exec sidekiq -C config/sidekiq.yml
  
  # Terminal 3: Rails console
  rails console
  
  # Send test email:
  participant = EventParticipant.first
  InvitationMailer.event_invitation(participant).deliver_later
  
  # Check Sidekiq terminal - should see job processed
  # Check log/development.log - should see email sent
  ```

### Step 2.5: Create Procfile for development (15 min)

- [ ] Create Procfile.dev
  ```
  web: bin/rails server -p 3000
  worker: bundle exec sidekiq -C config/sidekiq.yml
  ```

- [ ] Test with foreman
  ```bash
  gem install foreman
  foreman start -f Procfile.dev
  
  # Should start both Rails and Sidekiq
  # Visit http://localhost:3000
  # Visit http://localhost:3000/admin/sidekiq
  ```

- [ ] Commit changes
  ```bash
  git add -A
  git commit -m "Add Sidekiq for background jobs and email sending"
  ```

## PART 3: UPDATE DOCUMENTATION (2 hours)

### Step 3.1: Update README (1 hour)

- [ ] Replace README.md with the new version
  - Review and customize for your needs
  - Update email addresses
  - Update repository URLs
  - Add your contact info

- [ ] Test setup instructions
  - Follow your own README on a clean checkout
  - Fix any gaps or errors

### Step 3.2: Create deployment docs (30 min)

- [ ] Create docs/ folder
  ```bash
  mkdir docs
  ```

- [ ] Create docs/deployment.md
  - Copy relevant sections from README
  - Add production-specific settings
  - Document environment variables

### Step 3.3: Update .env.example (30 min)

- [ ] Create .env.example
  ```bash
  # Redis
  REDIS_URL=redis://localhost:6379/1
  
  # Email
  MAILER_FROM_EMAIL=events@confab.example.com
  SMTP_ADDRESS=smtp.sendgrid.net
  SMTP_PORT=587
  SMTP_USERNAME=apikey
  SMTP_PASSWORD=your-api-key
  
  # Database (production)
  DATABASE_URL=postgresql://user:pass@localhost/confab_production
  ```

- [ ] Add .env to .gitignore (if not already)
  ```bash
  echo ".env" >> .gitignore
  ```

- [ ] Commit documentation
  ```bash
  git add -A
  git commit -m "Add comprehensive documentation and deployment guide"
  ```

## FINAL STEPS (30 minutes)

### Test Everything Together

- [ ] Start fresh terminal session

- [ ] Start all services
  ```bash
  foreman start -f Procfile.dev
  ```

- [ ] Test complete workflow:
  1. [ ] Login as admin
  2. [ ] Create a test event
  3. [ ] Add participants
  4. [ ] Send bulk invitations
  5. [ ] Check Sidekiq dashboard - jobs processing
  6. [ ] Check email logs - emails sent
  7. [ ] User receives email
  8. [ ] User clicks RSVP link
  9. [ ] User submits RSVP
  10. [ ] User receives confirmation email

### Merge to main

- [ ] Run full test suite one more time
  ```bash
  bundle exec rspec
  ```

- [ ] Check git status
  ```bash
  git status
  git log --oneline -10
  ```

- [ ] Merge to main
  ```bash
  git checkout main
  git merge phase1-rsvp-fix-and-sidekiq
  git push origin main
  ```

### Deploy to production (if ready)

- [ ] Set environment variables on hosting platform
- [ ] Push to production
- [ ] Run migrations
- [ ] Verify Sidekiq worker is running
- [ ] Send test email in production

## SUCCESS METRICS

After completing Phase 1, you should have:

✅ **Data Model Fixed**
- No more rsvp_status on users table
- All RSVP queries use event_participants
- Tests passing

✅ **Background Jobs Working**
- Sidekiq installed and configured
- Emails sending in background
- Jobs visible in Sidekiq web UI

✅ **Documentation Complete**
- Comprehensive README
- Setup instructions tested
- Deployment guide created

✅ **Production Ready**
- Can handle your 4 proof-of-concept events
- Emails sending reliably
- Admin can manage events without crashes

## ESTIMATED TIME BREAKDOWN

| Task | Time |
|------|------|
| Preparation | 0.5 hr |
| Fix RSVP Data Model | 6 hr |
| Add Sidekiq | 4 hr |
| Update Documentation | 2 hr |
| Testing & Verification | 1.5 hr |
| **TOTAL** | **14 hr** |

At your billing rate: $130-170/hr = $1,820-2,380

## NEXT STEPS (Future Phases)

After completing Phase 1, consider:

**Phase 2 (Medium Priority):**
- Migrate to JSON columns
- Add database indexes
- Extract service objects

**Phase 3 (Nice to Have):**
- Improve test coverage
- Add monitoring tools
- Performance optimizations

---

**Questions or Issues?**
- Check each step carefully
- Test incrementally
- Commit after each major section
- Don't hesitate to rollback if something breaks

**You got this! 🚀**
