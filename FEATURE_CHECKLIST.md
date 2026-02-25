# evm1 Feature Status & Testing Checklist
**Updated:** February 22, 2026  
**Target deployment:** Sakuracon 2026  
**Production URL:** https://heybob-production.up.railway.app

---

## How to read this

- ✅ Built and deployed
- 🧪 Built — needs manual verification in production
- 🔨 In progress / partially built
- 📋 Backlog — designed, not started
- 💡 Future consideration

---

## CORE INFRASTRUCTURE

| Feature | Status | Test |
|---------|--------|------|
| User registration / Devise auth | ✅ | Sign up, sign in, password reset |
| Role system (5 roles) | ✅ | Verify super_admin, event_admin, venue_admin, vendor_admin, attendee all behave correctly |
| Admin::BaseController auth | ✅ | Non-admins should be redirected from /admin/* |
| Granular role enforcement | ✅ | event_admin can't access venues, venue_admin can't access vendors, etc. |
| external_id UUIDs on all records | ✅ | Check export endpoint for UUIDs |
| JSON export endpoint | ✅ | GET /admin/export — super_admin only |
| Railway deployment pipeline | ✅ | Push to main branch triggers deploy |
| APP_HOST env var | ✅ | Set to heybob-production.up.railway.app |

---

## EVENT MANAGEMENT

| Feature | Status | Test |
|---------|--------|------|
| Event CRUD (admin) | ✅ | Create, edit, delete events |
| Event types: hosted / participating / reference | ✅ | Form toggle, correct field visibility |
| External URL for participating/reference events | ✅ | Required validation fires |
| Venue assignment (optional) | ✅ | Can create event without venue |
| Slug auto-generation | ✅ | Create event, check slug in URL |
| Slug uniqueness guard (loop limit) | ✅ | Code guard added, hard to test manually |
| Event pagination | ✅ | /admin/events with >20 events |
| Custom RSVP questions | ✅ | Add questions in event form, verify on public page |
| Calendar .ics download | ✅ | Public event page → Add to Calendar |
| Public event page | ✅ | /e/:slug — no auth required |

---

## RSVP SYSTEM

| Feature | Status | Test |
|---------|--------|------|
| Public RSVP (no account) | ✅ | Submit RSVP as guest |
| Authenticated RSVP | ✅ | Login, RSVP to event |
| Update existing RSVP | ✅ | RSVP yes, return and change to maybe |
| RSVP confirmation page | ✅ | After submit, confirm page shows |
| RSVP deadline enforcement | ✅ | Past deadline → no RSVP form shown |
| Capacity tracking | ✅ | spots_remaining shows correctly |
| RSVP status display on dashboard | 🧪 | Login as attendee, check "My Events" |
| RSVP notification email | ✅ | Email sent on RSVP update |

---

## CHECK-IN SYSTEM

| Feature | Status | Test |
|---------|--------|------|
| QR code generation per participant | ✅ | View participant in admin, QR code present |
| QR code URL uses APP_HOST | ✅ (just fixed) | Check QR code URL points to Railway domain |
| QR scan check-in | 🧪 | Scan QR code with phone in production |
| Manual check-in (admin) | ✅ | Admin checkin dashboard |
| Bulk check-in | ✅ | Check-in all at once |
| Undo check-in | ✅ | Check in a participant, undo it |
| Check-in by event (dashboard) | ✅ | /admin/checkin/:event_id |
| Badge/QR print view | ✅ | Print badges page in admin |

---

## VENDOR SYSTEM

| Feature | Status | Test |
|---------|--------|------|
| Vendor registration | ✅ | Create vendor (business or artist type) |
| Vendor participant_type (business/artist) | ✅ | Toggle in vendor form |
| Social handles (instagram/twitter/tiktok) | ✅ | Add social links to vendor |
| VendorEvent (vendor at specific event) | ✅ | Assign vendor to event |
| VendorEvent category (dealer/artist_alley/sponsor/etc) | ✅ | Set category in vendor event form |
| Vendor QR opt-in flow | ✅ | Visit /vendor-optin/:token — QR landing page |
| Dynamic opt-in copy (business vs artist) | ✅ | Artist gets different headline than business |
| Visitor opt-in (attendee scans vendor QR) | ✅ | Scan, enter phone, confirm opt-in |
| Vendor SMS broadcast | ✅ | Send broadcast from vendor dashboard |
| Broadcast job (background) | ✅ | BroadcastSmsJob runs via Sidekiq |
| Vendor dashboard | ✅ | /vendor/dashboard |
| Admin vendor management | 🔨 | /admin/vendors — index exists, show/edit incomplete |

---

## TAXONOMY / CATEGORIZATION

| Feature | Status | Test |
|---------|--------|------|
| Category model (5 facets, parent/child) | ✅ | Check /admin/categories |
| Category seed data (32 categories) | ✅ | Run: `rails runner db/seeds/categories.rb` |
| Categorization seed (events tagged) | ✅ (today) | Run: `rails runner db/seeds/categorizations.rb` |
| Admin category CRUD | ✅ | Create/edit/deactivate categories |
| Category assignment to events (admin form) | ✅ | Checkboxes in event form, grouped by facet |
| Category display on public event page | ✅ | Tags shown on /e/:slug |
| Public events index with tag filtering | ✅ | /events and /events?tag=slug both live |
| Filterable URL scheme (Columbia River PLM) | ✅ | /events?tag=plm-tools-windchill confirmed working |
| User interest self-selection | 📋 | Phase 3 — after public filtering works |

---

## USER MANAGEMENT

| Feature | Status | Test |
|---------|--------|------|
| User CRUD (admin) | ✅ | /admin/users |
| Bulk user import (CSV) | 🧪 | Bulk Management button (just fixed redirect bug) |
| Bulk actions (promote/demote/delete) | 🧪 | Select users, apply bulk action |
| CSV export of users | ✅ | Export CSV button in bulk management |
| User profile edit | ✅ | /users/edit |
| Last-admin protection | ✅ | Cannot demote/delete last super_admin |
| Self-demotion prevention | ✅ | Admin cannot remove own privileges |

---

## VENUES

| Feature | Status | Test |
|---------|--------|------|
| Venue CRUD (admin) | ✅ | /admin/venues |
| Venue contact info fields | ✅ | Migration added contact_info column |
| Venue capacity display | ✅ | Shows on event pages |
| Venue optional on event | ✅ | Reference/participating events don't require venue |

---

## NOTIFICATIONS / COMMS

| Feature | Status | Test |
|---------|--------|------|
| RSVP confirmation email | ✅ | RSVP to event, check email |
| Bulk invitation email | ✅ | Bulk invite from admin event page |
| Invitation email template | ✅ | HTML + plain text versions |
| Twilio SMS (vendor broadcasts) | ✅ | Send broadcast, check Twilio logs |
| SMS phone normalization (E.164) | ✅ | 503-555-0100 → +15035550100 |

---

## UPCOMING WORK (prioritized)

### Sprint: Categorization UI (COMPLETE)
1. ✅ Category checkboxes on admin event edit form — grouped by facet
2. ✅ Category tags displayed on public event page
3. ✅ Public /events index with category filter links
4. ✅ Clean URL filtering: `/events?tag=plm-tools-windchill` → Columbia River PLM embed

### Next: Vendor Operations Layer (post-categorization)
5. 📋 Vendor dashboard — add booth number, load-in info, event logistics
6. 📋 Vendor onboarding checklist (booth confirmed, social links, QR message set)
7. 📋 Event-day admin cockpit — unified view: live check-in, vendor status, SMS blast
8. 📋 Admin vendor show/edit pages (complete the incomplete stub)

### Backlog
9. 📋 Event lifecycle status (draft / published / archived / cancelled)
10. 📋 Quick-add venue modal on event form (AJAX, injects into dropdown, no page reload)
11. 📋 Vendor analytics — opt-in count, scan trends (post-Sakuracon)
12. 📋 **Rethink event date/time fields** — current model has redundancy (`event_date` is datetime-local AND separate `start_time`/`end_time` fields). Proposed: store `start_date` + `end_date` (date only) + `start_time` + `end_time` (daily operating hours). Single-day events have same start/end date. Schema change — touches event form, public page, calendar download, seeds.

### Eventually / Needs Design Discussion
- **Multi-day scheduling complexity**: Sakuracon runs Thu–Sun with different hours per day, plus sub-areas (Vendor Hall, Artist Alley, Main Events) with their own schedules. Before building: decide how far into event scheduling we go. Full per-day/per-area scheduling exists in tools like Sched, Eventeny, Growtix — we don't want to replicate that. The sweet spot is probably: date range on the Event, load-in details on VendorEvent (not Event), and daily hours as a simple structured field if needed. Avoid scope creep into a full scheduling engine.
11. 📋 Vendor follower model (vendor-scoped, survives across events)
12. 📋 Public vendor profiles

### Future Considerations
13. 💡 User interest self-selection from taxonomy (Phase 3)
14. 💡 AI-assisted interest inference (Phase 4)
15. 💡 Multi-tenant / organization model
16. 💡 Mobile app / API layer

---

## KNOWN ISSUES

| Issue | Severity | Status |
|-------|----------|--------|
| Bulk Management redirect was going to root | High | ✅ Fixed today |
| QR codes had hardcoded localhost | High | ✅ Fixed today |
| Event#public_url had hardcoded localhost | Medium | ✅ Fixed today |
| load_users scope excluded non-attendee roles | Low | ✅ Fixed today |
| Pre-push checker false positives on `end` count | Noise | Known false positive — ruby -c passes |

---

## MANUAL TEST SCRIPTS

### Pre-Sakuracon smoke test (run before event day)
```
1. Visit /e/:slug — event page loads without login
2. Submit guest RSVP — confirmation page shows
3. Login as admin, go to /admin/checkin/:event_id
4. Scan a QR code with phone — check-in success page
5. Visit /vendor-optin/:token — opt-in flow works
6. Enter phone number — SMS received
7. Send vendor broadcast — all opted-in receive SMS
8. Export data — GET /admin/export returns valid JSON
```

### New feature verification (after each deploy)
```
1. Login works
2. /admin loads
3. /admin/events — events list
4. /admin/categories — categories list
5. /admin/bulk_users — bulk management loads (not root redirect)
6. Export data JSON has schema_version field
```
