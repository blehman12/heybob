# Shared Context — EVM1
> This file is maintained by the planning Claude (browser) after each conversation.
> Claude CLI reads it automatically on every `run-task` invocation.
> Last updated: 2026-03-23

---

## Project Snapshot
- **App**: HeyBob — Rails 7.1 event management (Sakuracon 2026 target)
- **Production**: https://heybob-production.up.railway.app
- **Deploy**: git push origin main → Railway auto-deploys (nixpacks)
- **DB**: PostgreSQL via Railway. Public networking enabled (yamanote.proxy.rlwy.net:15060)
- **Admin login**: admin@nwtg.com / password unknown (was Ch@ngeMe2026!, rejected in prod)
- **Test admin login**: admin@vendor.com (Vendor Test 1) — browser has password saved
- **Demo attendee**: demo@heybob.app / Demo1234! — RSVPed yes to Sakuracon 2026
- **Smoke test login**: smoketest@heybob.app / Sm0keTest!

## What Is Actually Built (verified Mar 23, 2026)

### Core / Infrastructure ✅
- User auth (Devise), 5-role RBAC, Admin::BaseController, external_id UUIDs
- Railway deployment pipeline + S3 Active Storage (aws-sdk-s3, production uses S3)
- Image uploads: vendor hero_image, venue photo, user avatar (all via Active Storage)
- Email via Resend API (noreply@crplm.com, crplm.com verified domain)

### Events ✅
- Full CRUD, lifecycle_status (draft/published/archived/cancelled), event types
- Lifecycle filter on admin events list with counts
- Public events index + tag filtering (/events?tag=slug)
- start_time / end_time columns exist in schema, displayed on public events index
- Slug generation, custom RSVP questions, calendar .ics export
- Quick-add venue modal (AJAX, no page reload)

### RSVP / Check-in ✅
- Public + authenticated RSVP, guest RSVP, confirmation page
- QR code check-in, manual check-in, bulk check-in, undo check-in, badge print view
- RSVP confirmation email + bulk invitation email

### Vendor System ✅
- Vendor CRUD (admin + vendor namespace), vendor dashboard (light theme, mobile-first)
- VendorEvent with booth logistics, QR opt-in flow (/join/:qr_token)
- SMS broadcast via Sidekiq/Twilio, BroadcastSmsJob with rate limiting
- Vendor analytics: hourly opt-in chart, broadcast delivery badges, Reached card, CSV export
- Vendor onboarding checklist (auto-hides when complete)
- Admin cockpit (/admin/events/:id/cockpit) — check-in stats, vendor table, broadcast log
- **Admin escape hatch**: "Admin" link in vendor header (only shown to admin users)

### Public Pages ✅
- Public vendor profiles (/vendors index + /vendors/:id show)
  - Hero image banner, categories, upcoming appearances with Follow button
  - Social links sidebar (Instagram, TikTok, Twitter)
  - Artist/Business filter
- Attendee dashboard (/) — logged-out = event discovery; logged-in = personal events + QR codes
  - Inline QR codes via rqrcode gem
  - Smart interest matching with "Show All" toggle
  - Admin/vendor_admin users redirected to their respective dashboards

### Taxonomy ✅
- 5-facet category model, 32 categories seeded, admin CRUD
- Category tagging on events/vendors, display on public pages, tag filtering

### User Management ✅
- User CRUD, bulk import/export, role management, last-admin protection
- Hero images displayed on admin show pages (vendor, venue, user)

### Interest Signups ✅
- /interest form (public), thank_you page, admin list with CSV export
- Navbar "Stay in the Loop" link (logged-out)

### Demo / Seed Data ✅
- Production: 9 users, 9 events, 8 venues, 6 vendors, 3 confirmed RSVPs
- Sakuracon 2026 (Apr 3): 5 vendors registered, 2 RSVPs
- demo@heybob.app RSVP'd yes to Sakuracon, QR code visible on dashboard

### Twilio / SMS ✅
- Credentials confirmed working in production
- Toll-free verification: **OVERDUE** — deadline was March 22, 2026. Status unknown.
  - Must complete steps 2+3 and resubmit ASAP
- **Trial account** — must upgrade to paid before SakuraCon (April 3)
- SAKURACON2026 QR token live at /join/SAKURACON2026

---

## Phantom Routes (in routes.rb but NO controller — will 500)
- `email_campaigns` — routes defined, no Admin::EmailCampaignsController
- `reports` — routes defined, no Admin::ReportsController
- These should be removed from routes.rb or stubbed

---

## Active Backlog (priority order)

### URGENT — Before April 3 (SakuraCon)
1. **Twilio toll-free verification** — OVERDUE (deadline was Mar 22). Complete steps 2+3 and resubmit immediately. SMS blocked until this is done.
2. **Twilio paid upgrade** — upgrade trial account to remove prefix and enable full volume
3. **KPOP CO setup** — hero image upload, Instagram/TikTok social handles, transfer ownership from admin@nwtg.com to real vendor user
4. **Admin password recovery** — admin@nwtg.com password unknown; need to reset via Rails console or Resend email

### UX Improvements (next focus area)
5. **RSVP confirmation page** — show QR code + Add to Calendar after RSVP (currently plain text)
6. **Vendor opt-in landing page polish** — /join/:qr_token copy/layout for non-Sakuracon events
7. **Attendee post-login flow** — after sign-in, redirect to dashboard not a blank page
8. **Empty states** — vendor dashboard with 0 opt-ins needs better guidance copy
9. **Mobile nav** — navbar collapses awkwardly on small screens (vendor pages fine, main app not)
10. **Follow button on vendor profile** — works but no confirmation/success state after clicking Follow

### Backlog
11. **Remove phantom routes** — email_campaigns + reports from routes.rb
12. **#12 Event date/time rethink** — multi-day event support
13. **#15 Smart Fill** — Claude API URL paste pre-fill for event creation
14. **Vendor analytics Phase 2** — cockpit leaderboard, heatmap, per-vendor broadcast summary
15. **Demo Vendor cleanup** — delete test "Demo Vendor" (vendor ID 6) created during walkthrough

---

## Key Architectural Decisions
- Prefer migrations over seed scripts for production data — migrations auto-run on deploy
- To run scripts from WSL against prod DB: `railway run bash -c 'DATABASE_URL=$DATABASE_PUBLIC_URL bundle exec rails runner db/seeds/foo.rb'`
- Every task.md must list every `git add` explicitly — no ambiguous staging instructions
- Three deploy modes: local (no push), light (push), full (push + smoke test)
- Claude CLI runs from WSL at /mnt/c/evm1 with --dangerously-skip-permissions
- Admin checkin routes are **nested member routes under `resources :events`** (not flat)
- Vendor namespace uses shallow: true — vendor_event routes don't need vendor_id prefix

## Known Gotchas for Claude CLI
- Ruby is in WSL only — not available in Windows Git Bash
- Event form has TWO input[name="event[event_date]"] fields (duplicate bug, known)
- seeds.rb has `return if Rails.env.production?` guard — safe to run locally
- Pre-push hook warns "ruby not found" — false positive in Windows context, ignore
- VendorEvent metadata is JSON — always use extract_metadata() pattern, never overwrite whole field
- Admin::VendorsController find_or_create_owner fails silently on unknown email (User needs phone+company)
- routes.rb admin namespace starts ~line 80, indentation is messy
- Chrome extension disconnects on wait > 20s — avoid computer wait over 20 seconds
- **Never name a controller action `process`** — conflicts with ActionController::Metal#process
- JS `.click()` on forms selects Sign Out button first — use specific selectors or direct mouse clicks
- fetch() form submissions cause CSRF session reset in this app — use direct mouse clicks for forms

---

## Key File Locations
- Routes:                  config/routes.rb
- Admin events ctrl:       app/controllers/admin/events_controller.rb
- Admin events index:      app/views/admin/events/index.html.erb
- Admin checkin ctrl:      app/controllers/admin/checkin_controller.rb
- Public checkin ctrl:     app/controllers/checkin_controller.rb
- Public events ctrl:      app/controllers/public_events_controller.rb
- Public events index:     app/views/public_events/index.html.erb
- Public vendors ctrl:     app/controllers/public_vendors_controller.rb
- Public vendors index:    app/views/public_vendors/index.html.erb
- Public vendors show:     app/views/public_vendors/show.html.erb
- Interest signup ctrl:    app/controllers/interest_signups_controller.rb
- Interest signup (admin): app/controllers/admin/interest_signups_controller.rb
- App layout:              app/views/layouts/application.html.erb
- Vendor layout:           app/views/layouts/vendor_dashboard.html.erb
- Vendor dashboard CSS:    app/assets/stylesheets/vendor_dashboard.css
- Vendor event ctrl:       app/controllers/vendor/vendor_events_controller.rb
- Cockpit view:            app/views/admin/events/cockpit.html.erb
- Attendee dashboard:      app/views/dashboard/index.html.erb
- Dashboard ctrl:          app/controllers/dashboard_controller.rb
- Task file:               .claude/task.md
- This file:               .claude/context.md
