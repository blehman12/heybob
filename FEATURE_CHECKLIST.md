# evm1 Feature Status & Testing Checklist
**Updated:** March 8, 2026
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
| Admin vendor management | ✅ | /admin/vendors — index, show, edit, new, import all complete |
| Vendor event logistics (booth, hall, load-in) | ✅ | Edit from vendor event show page |
| Vendor onboarding checklist | ✅ | Auto-shown on vendor event show until all 4 items done |
| Admin dashboard vendor links | ✅ | Vendor stat card + Manage/New Vendors in quick actions |

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

### Sprint: Vendor Operations Layer (COMPLETE)
5. ✅ Vendor event logistics panel — booth number, hall, load-in date/time/notes (edit form)
6. ✅ Vendor onboarding checklist — 4-item checklist auto-hides when all done
7. ✅ Event-day admin cockpit — `/admin/events/:id/cockpit` — check-in stats, vendor table, broadcast log
8. ✅ Admin vendor show/edit pages — complete with import, all CRUD actions

### Backlog
9. ✅ Event lifecycle status (draft / published / archived / cancelled)
10. ✅ Quick-add venue modal on event form (AJAX, injects into dropdown, no page reload)
11. ✅ **Vendors link in admin navbar** — added Mar 15 2026. Dashboard → Events → Venues → Vendors → Users on all admin screens.
13. ✅ **General interest / waitlist page** — COMPLETED Mar 2026. Navbar link (logged-out), CTA banner on events index, admin dashboard stat card + quick action, CSV export.
12. 📋 **Rethink event date/time fields** — current model has redundancy (`event_date` is datetime-local AND separate `start_time`/`end_time` fields). Proposed: store `start_date` + `end_date` (date only) + `start_time` + `end_time` (daily operating hours). Single-day events have same start/end date. Schema change — touches event form, public page, calendar download, seeds.
14. ✅ **Portland/Seattle demo seed data** — 6 PNW venues + 8 PLM/tech events seeded. Deployed Feb 27.
15. 📋 **Smart Fill via URL paste** — user pastes any public URL (company site, Meetup, LinkedIn event) on event/venue creation form. We fetch it, Claude API extracts name/description/date/location, pre-fills the form. No OAuth. Works with any public URL. Fraction-of-a-cent per call. Medium lift, high demo value.
16. 📋 **Context-aware defaults** — no AI. Pre-fill new event forms from last used venue, creator name, previous event categories, current date +30 days. Easy UX win, do after Smart Fill.

### Sprint: Hero Image & Visual Polish (NEW — Mar 15 2026)
17. 📋 **Hero image on admin show pages** — vendor, venue, and user admin show pages display uploaded image at top of detail card. Acceptance: image shows if attached; initial/placeholder shows if not. Both states error-free.
18. 📋 **Hero image in admin list/table views** — small thumbnail (40x40px) in leftmost column of vendors, venues, users index tables. Shows placeholder initial if no image. Makes scanning lists faster.
19. 📋 **Grid view for vendors/events** — card grid layout as alternative to table view. Each card shows hero image, name, key metadata. Toggle between grid and table. High visual impact for demos.

### Sprint: End User Experience (NEW — Mar 15 2026)
*Goal: Give logged-in attendees something to do beyond RSVP. Needed before SakuraCon.*

20. 📋 **"My Events" on attendee dashboard** — list of events user has RSVPed to with status badge (yes/maybe/no/pending), event date, check-in status. Currently shows nothing useful for attendees.
21. 📋 **Post-RSVP confirmation page with QR + calendar** — after RSVPing yes, show the user their check-in QR code and an "Add to Calendar" button on the confirmation page. Reduces "where's my ticket?" support asks.
22. 📋 **Public vendor profiles** — `/vendors/:slug` public page showing vendor hero image, description, social links, and events they're attending. Lets attendees discover and follow vendors before the event.
23. 📋 **Follow a vendor from public profile** — opt-in button on public vendor profile page. Creates a `ConOptIn` record linked to the vendor's active event. Same as scanning the QR but web-accessible.

---

## FEATURE #11 — VENDOR ANALYTICS

**Goal**: Give vendors actionable data about their booth performance and give organizers a macro view of floor traffic. Build from existing data first; add collection mechanisms later.

**Design principles**:
- Phase 1 uses 100% existing data — no schema changes
- Simple charts + CSV export; let vendors do their own deep analysis
- Build better analytics after seeing how Phase 1 is actually used
- "Did I make booth?" can't be answered with revenue data we don't have, but we can give meaningful visit proxies

---

### Phase 1 — Vendor Dashboard Enhancements (no schema changes)

Surfaces existing `con_opt_ins`, `broadcast_receipts` data in the vendor's own view.

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 11.1 | **Hourly opt-in chart** — time-of-day bar chart (bucket `opted_in_at` by hour) on vendor event show page. Shows peak traffic hours. | ✅ | Already existed — `@opt_in_timeline` GROUP BY hour query + inline HTML bar chart |
| 11.2 | **Broadcast performance row** — under each broadcast on vendor event show page: "Sent X · Delivered Y · Failed Z" colored badge row | ✅ | Green ✓ / red ✗ / grey ⏳ badges — in-memory on eager-loaded receipts |
| 11.3 | **Reach stat card** — "X unique people reached via broadcasts" (distinct `con_opt_in_id` across all delivered receipts for this vendor event) | ✅ | 4th stat card added; `@reached_count` query in show action; CSS grid bumped to repeat(4,1fr) |
| 11.4 | **CSV export of opt-in list** — "Export Contacts" button on vendor event show page. Columns: Name, Phone, Email, Opted In At. Vendor's post-show follow-up sheet. | ✅ | `export_contacts` member route + action + "↓ Export contacts" link above timeline |

---

### Phase 2 — Organizer Floor View (no schema changes)

Gives event organizers a macro picture of booth traffic across the whole event. Lives in admin cockpit.

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 11.5 | **Booth leaderboard** — on admin event cockpit, rank vendors by opt-in count. Shows which booth/panel/guest drew the most traffic. | 📋 | One query on `vendor_opt_ins` grouped by `vendor_event_id` |
| 11.6 | **Event-wide traffic heatmap** — hourly bar chart of all opt-ins across the entire event (all vendors combined). Shows when the floor was busiest. | 📋 | Same hour-bucket query as 11.1, scoped to event |
| 11.7 | **Per-vendor broadcast summary** — admin cockpit table: for each vendor, show broadcast count + total reach + delivery rate. Quick health check. | 📋 | Aggregated from `broadcasts` + `broadcast_receipts` |

---

### Phase 3 — Repeat Visitor + Post-Event (minor schema additions, larger value)

Builds loyalty signals and post-show follow-up tooling. Design before building.

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 11.8 | **Repeat visitor detection** — "X people have found you at more than one event." Match `con_opt_ins.phone` (or email) across multiple events for the same vendor. Loyalty signal. | 💡 | Query only — no schema change. Needs multi-event vendor history to be useful. |
| 11.9 | **Post-event follow-up list** — "Who haven't you messaged yet?" Opt-ins who never received a broadcast. Exportable. | 💡 | LEFT JOIN `broadcast_receipts` to `vendor_opt_ins`, show non-recipients |
| 11.10 | **Cross-event comparison** — "How does this show compare to your last one?" Side-by-side stat cards (opt-in count, delivery rate, reach). | 💡 | Needs vendor to have 2+ VendorEvents to be meaningful |

---

### Parking Lot — End-User "Con Recap" (Phase 3+, needs design)

Separate from vendor analytics but surfaced during the #11 brainstorm. Attendee-facing post-event experience.

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 11.A | **"What did I miss?"** — post-event digest for attendees. Panels, booths, guests they didn't visit. | 💡 | Needs attendee check-in at booths (not just opt-in) to know what they *did* visit |
| 11.B | **Social follow suggestions** — "Follow these vendors on Instagram after the show." Surfaces vendor social handles to opted-in attendees. | 💡 | Data exists (`vendor.social_handles`); needs delivery mechanism (email or feed) |
| 11.C | **Post-con purchasing** — link to vendor storefronts after the event. "Buy that print you saw at Sakuracon." | 💡 | Needs vendor storefront URL field + attendee-facing post-event page |
| 11.D | **"Stay in touch" hub** — opted-in attendees get a persistent link to the event feed + vendor updates after the show closes. Ties into #13 interest signups. | 💡 | Extends existing `ConOptIn` + event feed concept |

---

### AI Feature Decision Log (Feb 26, 2026)
Discussed three tiers of AI-assisted pre-population:
- **Rejected (for now)**: LinkedIn/Facebook/Gmail OAuth scraping — ToS issues, huge scope, not worth it yet
- **Approved for later**: Smart Fill via URL paste (Claude API, any public URL, no OAuth) — medium lift, high value. Revisit when demo needs to impress.
- **Approved for later**: Context-aware defaults (no AI, just smart UX) — easy, lower priority than Smart Fill
- **Priority order agreed**: #10 venue modal → seed data → Smart Fill → context-aware defaults
- **Revisit trigger**: When app is being shown to external stakeholders or PLM community and needs to feel "alive"

### Eventually / Needs Design Discussion
- **Multi-day scheduling complexity**: Sakuracon runs Thu–Sun with different hours per day, plus sub-areas (Vendor Hall, Artist Alley, Main Events) with their own schedules. Before building: decide how far into event scheduling we go. Full per-day/per-area scheduling exists in tools like Sched, Eventeny, Growtix — we don't want to replicate that. The sweet spot is probably: date range on the Event, load-in details on VendorEvent (not Event), and daily hours as a simple structured field if needed. Avoid scope creep into a full scheduling engine.
- 📋 Vendor follower model (vendor-scoped, survives across events)
- 📋 Public vendor profiles

### Future Considerations
- 💡 User interest self-selection from taxonomy (Phase 3)
- 💡 AI-assisted interest inference (Phase 4)
- 💡 Multi-tenant / organization model
- 💡 Mobile app / API layer

---

## KNOWN ISSUES

| Issue | Severity | Status |
|-------|----------|--------|
| Bulk Management redirect was going to root | High | ✅ Fixed today |
| QR codes had hardcoded localhost | High | ✅ Fixed today |
| Event#public_url had hardcoded localhost | Medium | ✅ Fixed today |
| load_users scope excluded non-attendee roles | Low | ✅ Fixed today |
| Pre-push checker false positives on `end` count | Noise | Known false positive — ruby -c passes |
| `find_or_create_owner` in Admin::VendorsController | Low | Creates User without required phone/company — silent 422 for unknown emails. Workaround: use existing user email when creating vendors. |

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
