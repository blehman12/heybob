# PHASE 1 QUICK REFERENCE CARD
# Keep this handy while implementing changes

## 🔴 CRITICAL CHANGES SUMMARY

### 1. USER MODEL - WHAT TO REMOVE
```ruby
# ❌ REMOVE THESE from User model:
enum rsvp_status: { pending: 0, yes: 1, no: 2, maybe: 3 }  # DELETE THIS

# ✅ KEEP ONLY:
enum role: { attendee: 0, admin: 1 }  # This one stays!
```

### 2. DATABASE MIGRATION - WHAT TO REMOVE FROM USERS TABLE
```ruby
# Removes these columns from users:
- rsvp_status
- invited_at  
- calendar_exported
```

### 3. CONTROLLER QUERIES - SEARCH AND REPLACE

**Find this pattern:**
```ruby
# ❌ WRONG (queries users table):
.joins(:user).where(users: { rsvp_status: User.rsvp_statuses[:yes] })
```

**Replace with:**
```ruby
# ✅ CORRECT (queries event_participants):
.where(rsvp_status: :yes)
```

**Specific locations:**
- `app/controllers/admin/events_controller.rb` line 19-23
- `app/controllers/admin/events_controller.rb` line 67-71

### 4. EMAIL CHANGES - DELIVER NOW → DELIVER LATER

**Find this:**
```ruby
# ❌ OLD WAY (blocks request):
SomeMailer.some_email(user).deliver_now
```

**Replace with:**
```ruby
# ✅ NEW WAY (background job):
SomeMailer.some_email(user).deliver_later(queue: :mailers)
```

## 📁 FILES TO CREATE

```
config/
  └── sidekiq.yml                    # New file
  └── initializers/
      └── sidekiq.rb                 # New file

app/
  └── views/
      └── invitation_mailer/
          ├── event_invitation.html.erb   # New file
          └── event_invitation.text.erb   # New file

Procfile.dev                         # New file
.env.example                         # New file
docs/
  └── deployment.md                  # New file
```

## 📝 FILES TO MODIFY

```
Gemfile                              # Add sidekiq
config/application.rb                # Add queue adapter
config/routes.rb                     # Add Sidekiq web UI
app/models/user.rb                   # Remove rsvp_status enum
app/models/event_participant.rb      # (no changes needed - already correct!)
app/controllers/admin/events_controller.rb  # Fix queries
app/mailers/invitation_mailer.rb     # Enhance with new methods
README.md                            # Replace completely
```

## 🔧 GEMFILE ADDITIONS

```ruby
# Add to Gemfile:
gem 'sidekiq', '~> 7.2'

# Then run:
bundle install
```

## ⚙️ CONFIG SNIPPETS

### config/application.rb
```ruby
# Add this line inside the Application class:
config.active_job.queue_adapter = :sidekiq
```

### config/routes.rb
```ruby
# Add inside namespace :admin do
require 'sidekiq/web'
authenticate :user, ->(user) { user.admin? } do
  mount Sidekiq::Web => '/sidekiq'
end
```

## 🚀 RUNNING LOCALLY

### Option 1: Separate terminals
```bash
# Terminal 1:
rails server

# Terminal 2:
redis-server

# Terminal 3:
bundle exec sidekiq -C config/sidekiq.yml
```

### Option 2: Foreman (easier)
```bash
foreman start -f Procfile.dev
```

## 🧪 TESTING THE CHANGES

### Test 1: Data Model Fix
```bash
rails console

# This should error (no more rsvp_status on User):
User.first.rsvp_status  # ❌ Should raise NoMethodError

# This should work:
EventParticipant.first.rsvp_status  # ✅ Should return "pending", "yes", etc
```

### Test 2: Background Jobs
```bash
rails console

# Send test email:
participant = EventParticipant.first
InvitationMailer.event_invitation(participant).deliver_later

# Should see in Sidekiq logs:
# InvitationMailer#event_invitation performed in XXms
```

### Test 3: Admin Dashboard
```bash
# Visit in browser:
http://localhost:3000/admin/events/1

# Check that RSVP counts display correctly
# Should show: "3 Yes, 2 No, 1 Maybe, 5 Pending" or similar
```

## 🐛 COMMON ERRORS & FIXES

### Error: "undefined method `rsvp_status' for #<User>"
**Fix:** You missed removing the enum from User model or a view still references user.rsvp_status

### Error: "Redis connection refused"
**Fix:** Start Redis: `redis-server` or `brew services start redis`

### Error: "Sidekiq doesn't start"
**Fix:** Check config/sidekiq.yml exists and Redis is running

### Error: "Emails not sending"
**Fix:** 
1. Check Sidekiq is running
2. Check logs: `tail -f log/sidekiq.log`
3. Visit: http://localhost:3000/admin/sidekiq

## 📊 VERIFICATION CHECKLIST

Before considering Phase 1 complete:

- [ ] Migration ran successfully: `rails db:migrate`
- [ ] Tests pass: `bundle exec rspec`
- [ ] No references to `user.rsvp_status` in code: `grep -r "user.rsvp_status" app/`
- [ ] Sidekiq starts: `bundle exec sidekiq -C config/sidekiq.yml`
- [ ] Sidekiq web UI loads: http://localhost:3000/admin/sidekiq
- [ ] Test email sends in background
- [ ] Admin event page shows RSVP counts correctly
- [ ] README.md has setup instructions

## 🎯 SUCCESS CRITERIA

After Phase 1, you can:

1. ✅ Create an event
2. ✅ Invite participants via bulk action
3. ✅ Participants receive invitation emails (in background)
4. ✅ Admin sees correct RSVP counts
5. ✅ No errors in logs
6. ✅ Sidekiq processing jobs reliably
7. ✅ New developer can setup app from README

## 💡 PRO TIPS

1. **Commit often** - After each section of the checklist
2. **Test incrementally** - Don't wait until the end
3. **Use git branches** - Easy to rollback if needed
4. **Check Sidekiq UI** - Great for debugging email issues
5. **Read the logs** - `tail -f log/development.log` shows everything

## 📞 NEED HELP?

If you get stuck:
1. Check the error message carefully
2. Search the full code review PDF
3. Check SIDEKIQ_SETUP.md for Sidekiq issues
4. Rollback to last working commit: `git reset --hard HEAD~1`

---

**Estimated time:** 14 hours total
**Difficulty:** Moderate (one tricky migration, rest is straightforward)
**Risk:** Low (good test coverage, can rollback migration)

**You're fixing a fundamental data model issue and adding production-ready email. This is important work! Take your time and test thoroughly.**

🚀 Let's ship Phase 1!
