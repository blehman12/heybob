# AUTOMATION SCRIPTS - USAGE GUIDE

## 📦 What You Have

You now have **4 powerful automation scripts** that handle Phase 1 implementation:

1. **`run_phase1.sh`** - Master control panel (START HERE)
2. **`phase1_install.sh`** - Full automated installation
3. **`phase1_verify.sh`** - Verification and testing
4. **`phase1_rollback.sh`** - Safe rollback if needed

## 🚀 QUICK START (2 Minutes)

```bash
# 1. Navigate to your Confab project
cd /path/to/confab

# 2. Copy all Phase 1 files to your project directory
# (All the .sh, .rb, .md, and .erb files)

# 3. Run the master script
chmod +x run_phase1.sh
./run_phase1.sh

# 4. Select Option 1: Install Phase 1
# 5. Follow the prompts (takes ~15-20 minutes)
# 6. Done! ✓
```

## 📋 DETAILED USAGE

### Option 1: Use the Master Control Panel (RECOMMENDED)

The master control panel (`run_phase1.sh`) provides an interactive menu:

```bash
./run_phase1.sh
```

**Menu Options:**
- **1) Install Phase 1** - Full automated implementation
- **2) Verify Installation** - Check everything is correct
- **3) Show Status** - See what's installed
- **4) Rollback** - Undo changes if needed
- **5) View Documentation** - Read guides
- **6) Test Components** - Test individual parts
- **7) Next Steps** - What to do after installation

### Option 2: Run Scripts Individually

If you prefer more control:

```bash
# Step 1: Install
chmod +x phase1_install.sh
./phase1_install.sh

# Step 2: Verify
chmod +x phase1_verify.sh
./phase1_verify.sh

# Step 3 (if needed): Rollback
chmod +x phase1_rollback.sh
./phase1_rollback.sh
```

### Option 3: Auto-Install (No Prompts)

For automation or CI/CD:

```bash
./phase1_install.sh --yes
```

This skips all confirmation prompts.

## 📁 FILE PLACEMENT

All files should be in your Confab project root:

```
confab/
├── app/
├── config/
├── db/
├── ...
├── run_phase1.sh                      ← Master script
├── phase1_install.sh                  ← Installation
├── phase1_verify.sh                   ← Verification
├── phase1_rollback.sh                 ← Rollback
├── 20260211_fix_rsvp_data_model.rb   ← Migration template
├── user_model_fixed.rb                ← Fixed User model
├── events_controller_fixed.rb         ← Fixed controller
├── invitation_mailer.rb               ← Mailer
├── event_invitation.html.erb          ← Email template
├── INDEX.md                           ← Documentation index
├── QUICK_REFERENCE.md                 ← Quick reference
├── PHASE1_CHECKLIST.md                ← Manual checklist
├── SIDEKIQ_SETUP.md                   ← Sidekiq guide
└── README.md                          ← Project README
```

## ⚙️ WHAT THE SCRIPTS DO

### `run_phase1.sh` - Master Control Panel

**Interactive menu with:**
- Installation orchestration
- Status checking
- Documentation access
- Component testing
- Help system

**Use when:** You want a guided experience

### `phase1_install.sh` - Automated Installation

**Performs:**
- ✅ Creates backups (database + files)
- ✅ Creates git branch for safety
- ✅ Adds Sidekiq to Gemfile
- ✅ Creates and runs migration
- ✅ Updates User model
- ✅ Updates Admin::EventsController
- ✅ Updates InvitationMailer
- ✅ Creates Sidekiq config files
- ✅ Updates Rails application config
- ✅ Creates Procfile.dev
- ✅ Creates .env.example
- ✅ Updates README.md
- ✅ Checks for code issues
- ✅ Runs tests
- ✅ Commits to git

**Use when:** You want full automation

### `phase1_verify.sh` - Verification

**Checks:**
- ✅ Database migration status
- ✅ Model files correct
- ✅ Controller queries fixed
- ✅ Sidekiq installed and configured
- ✅ Mailer files present
- ✅ Configuration files created
- ✅ Documentation updated
- ✅ No code quality issues
- ✅ Tests passing
- ✅ Email system functional

**Use when:** You want to confirm installation

### `phase1_rollback.sh` - Safe Rollback

**Performs:**
- ✅ Rolls back database migration
- ✅ Restores backed up files
- ✅ Restores database file
- ✅ Removes git branch
- ✅ Returns to previous state

**Use when:** Something went wrong

## 🔍 VERIFICATION EXAMPLES

After installation, verify with these tests:

```bash
# Test 1: Check migration worked
rails console
> User.column_names.include?('rsvp_status')
=> false  # Should be false (removed)

> EventParticipant.column_names.include?('rsvp_status')
=> true   # Should be true (correct location)

# Test 2: Check Sidekiq
redis-cli ping
# Should return: PONG

# Test 3: Check email system
rails console
> participant = EventParticipant.first
> InvitationMailer.event_invitation(participant).deliver_later
# Should queue job successfully

# Test 4: View Sidekiq dashboard
open http://localhost:3000/admin/sidekiq
# Should show web UI
```

## 🐛 TROUBLESHOOTING

### Script won't run
```bash
# Make executable
chmod +x run_phase1.sh phase1_install.sh phase1_verify.sh phase1_rollback.sh
```

### "Not in Rails project directory"
```bash
# Navigate to your project first
cd /path/to/confab
pwd  # Should show confab directory
ls config/application.rb  # Should exist
```

### Redis errors
```bash
# Mac
brew install redis
brew services start redis

# Linux
sudo apt-get install redis-server
sudo systemctl start redis
```

### Migration fails
```bash
# Check current migrations
rails db:migrate:status

# Try rollback
rails db:rollback

# Re-run script
./run_phase1.sh
```

### Tests fail
```bash
# Update test database
RAILS_ENV=test rails db:migrate

# Check for user.rsvp_status in specs
grep -r "user.rsvp_status" spec/
# Update any found references
```

### Sidekiq won't start
```bash
# Check Redis
redis-cli ping

# Check config file
cat config/sidekiq.yml

# Check logs
tail -f log/sidekiq.log
```

## ⏱️ TIME ESTIMATES

| Task | Automated | Manual |
|------|-----------|--------|
| Installation | 15-20 min | 6-8 hours |
| Verification | 2-5 min | 1 hour |
| Testing | 5 min | 2 hours |
| Documentation | 0 min | 2 hours |
| **TOTAL** | **~30 min** | **~14 hours** |

**Time saved:** 13-14 hours!

## 📊 SAFETY FEATURES

All scripts include:

✅ **Backups** - Database and files backed up before changes
✅ **Git branches** - Changes isolated in separate branch
✅ **Rollback** - Can undo everything safely
✅ **Error handling** - Auto-rollback on errors
✅ **Verification** - Checks before and after
✅ **Logging** - Tracks all changes made

## 🎯 RECOMMENDED WORKFLOW

**First time installation:**

1. Run `./run_phase1.sh`
2. Choose Option 3 (Show Status) - see current state
3. Choose Option 1 (Install) - full installation
4. Wait ~15-20 minutes
5. Choose Option 2 (Verify) - confirm success
6. Choose Option 7 (Next Steps) - see what to do next

**If something goes wrong:**

1. Run `./run_phase1.sh`
2. Choose Option 4 (Rollback)
3. Fix the issue manually
4. Try installation again

**After successful installation:**

1. Start Redis: `redis-server`
2. Start app: `foreman start -f Procfile.dev`
3. Visit: `http://localhost:3000`
4. Create an event and test invitations!

## 📞 GETTING HELP

**Built-in help:**
```bash
./run_phase1.sh
# Choose Option 7: Next Steps / Help
```

**Manual help:**
- Read `QUICK_REFERENCE.md` for critical changes
- Read `PHASE1_CHECKLIST.md` for step-by-step guide
- Read `SIDEKIQ_SETUP.md` for Sidekiq details
- Read `confab_code_review.md` for complete analysis

**Still stuck?**
- Check git status: `git status`
- Check logs: `tail -f log/development.log`
- Check Sidekiq: `tail -f log/sidekiq.log`
- Rollback and try again

## ✅ SUCCESS CRITERIA

Installation is successful when:

- [ ] Migration ran (`User.column_names` excludes `rsvp_status`)
- [ ] Sidekiq in Gemfile
- [ ] Sidekiq config files created
- [ ] Models updated
- [ ] Controllers updated
- [ ] Mailers created
- [ ] Email templates exist
- [ ] Procfile.dev created
- [ ] README.md updated
- [ ] Tests pass (or failures documented)
- [ ] Redis running
- [ ] Sidekiq can start
- [ ] Emails queue successfully

## 🎉 AFTER INSTALLATION

You'll be ready for your 4 POC events:
- Cinco de Mayo Party
- Windchill Spring Event
- Sakurako Anima Event
- Poe Show Follow-up

**Next phase (optional):**
- Phase 2: JSON columns, indexes, service objects
- Phase 3: Test coverage, monitoring, performance

---

## 💡 PRO TIPS

1. **Always verify** after installation
2. **Keep backups** - scripts create them automatically
3. **Use git** - scripts create branches for safety
4. **Test incrementally** - use component tests
5. **Read the output** - scripts explain what they're doing
6. **Don't panic** - rollback is always available

## 🚀 YOU'RE READY!

These scripts automate ~14 hours of manual work into 20 minutes. They include:

- ✅ Safety checks and backups
- ✅ Error handling and rollback
- ✅ Verification and testing
- ✅ Documentation and help
- ✅ Interactive guidance

**Start with:** `./run_phase1.sh`

Good luck with your implementation! 🎯
