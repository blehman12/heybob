# HeyBob — SakuraCon 2026 Pre-Event QA Scenarios

**App**: https://heybob-production.up.railway.app
**Event**: SakuraCon 2026, April 3–6, Seattle
**Test by**: April 2

---

## Persona 1: Sarah — First-Time Attendee (no account, mobile)

**Goal**: Find SakuraCon, RSVP, and show up ready to check in.

### 1. Browse events
- URL: `/events`
- ✅ Verify: SakuraCon appears, page works on mobile (no horizontal scroll)
- ⚠️ Watch: Is the RSVP deadline set to April 3 or later? If it's already passed, the form is hidden.

### 2. View event page
- URL: `/e/sakuracon-2026`
- ✅ Verify: Date, venue address, description visible. Guests section shows photos. Sponsors section shows logos.
- ⚠️ Watch: Blank venue address is a problem for a first-timer.

### 3. Submit guest RSVP
- ✅ Verify: Form works without an account. Name required, phone or email required.
- 🧪 Test cases:
  - Name only → validation error
  - Name + invalid email → error
  - Name + valid phone → success → confirmation page with QR
  - Same phone twice → friendly duplicate message, not 500

### 4. Confirmation page
- ✅ Verify: QR code renders large enough to scan. "Add to Calendar" works.
- ⚠️ Watch: Opening the confirmation URL in a new browser should show access denied (session-based), not the page.

### 5. Check in at the door (day of)
- QR → `/checkin/verify?token=X&event=Y&participant=Z`
- ✅ Verify: Scans with phone camera. Shows Sarah's name. "Check In" button works. Success screen appears.
- ⚠️ Watch: **Critical** — confirm `APP_HOST` is `heybob-production.up.railway.app`, not localhost. Scan the actual QR to verify.

---

## Persona 2: Marcus — Artist Alley Vendor, Booth A-12

**Goal**: Set up profile, display QR at booth, collect opt-ins, send Saturday SMS broadcast.

### 1. Log in to vendor portal
- Credentials: vendor1@coretech.com / Vendor123!
- ✅ Verify: Redirects to `/vendor` dashboard, not admin. SakuraCon 2026 appears.

### 2. Edit vendor profile
- URL: `/vendor/vendors/:id/edit`
- ✅ Verify: Can update name, bio, social handles. Hero image upload works (test with a JPG).
- ⚠️ Watch: If image processing fails silently, thumbnail won't appear on public profile.

### 3. Find booth QR code
- URL: `/vendor/vendor_events/:id`
- ✅ Verify: QR code image renders. Booth number A-12 shows. Scan QR → opens correct opt-in URL on production domain.
- 🚨 Critical: Scan the QR with a real phone. Confirm URL is `heybob-production.up.railway.app/join/...`, not `localhost`.

### 4. Simulate visitor scanning QR
- URL: `/join/:qr_token` (on phone, logged out)
- ✅ Verify: Shows vendor name and pitch. Form works without an account.
- 🧪 Test cases:
  - Name + phone, SMS checkbox checked → success
  - Name + email only → success
  - Name only → validation error
  - Same phone twice → friendly duplicate, not 500

### 5. Send SMS broadcast
- URL: `/vendor/vendor_events/:id/broadcast`
- ✅ Verify: 160-char counter works. Submitting queues job. Recipients count shown.
- ⚠️ Watch: Twilio trial account ($12.16 remaining) — upgrade before April 3. Toll-free verification still pending.

---

## Persona 3: Jen — Event Coordinator / Admin

**Goal**: Verify data pre-event, check in stragglers, monitor attendance.

### 1. Audit the event record
- URL: `/admin/events/:id`
- ✅ Verify: All fields correct. `public_rsvp_enabled` is on. RSVP deadline is set. Max attendees set. "Public ↗" link opens correct URL.

### 2. Review participant list
- URL: `/admin/events/:id/participants`
- ✅ Verify: Counts correct. Guest rows show guest_name (not blank). CSV export works without crashing.
- 🚨 Critical: Download CSV and open in Excel — confirm guest rows have names/emails (not blank — this was a fixed bug).

### 3. Manual check-in (lost QR)
- URL: `/admin/checkin/dashboard/:event_id`
- ✅ Verify: Search by name finds participant. "Check In" marks them as `manual`. Count increments.
- ⚠️ Watch: Load time with 500+ participants — if over 2 seconds, note it.

### 4. Bulk check-in
- ✅ Verify: Multi-select checkboxes work. Bulk Check In processes all selected rows with method: `bulk`.

### 5. Monitor Sidekiq
- URL: `/admin/sidekiq`
- ✅ Verify: Dashboard loads (super_admin only). Queue depth near 0. No jobs in Dead queue.

---

## Persona 4: David — Curious Walk-In (no account, Android)

**Goal**: Browse vendors, scan a QR, maybe follow someone — all without an account.

### 1. Browse public vendor list
- URL: `/vendors`
- 🚨 Critical: Page must load without login. If it redirects to sign-in, this is broken.
- ✅ Verify: Grid/list toggle works. Filter by Artist/Business works. Mobile-friendly.

### 2. View vendor profile
- URL: `/vendors/:id`
- ✅ Verify: Follow form is present without needing an account. Name required, phone or email required.

### 3. Scan booth QR
- URL: `/join/:qr_token`
- ✅ Verify: Loads fast (under 3s on 4G). SMS consent language is clear and present. Skip/no-thanks link visible.

### 4. View event feed post opt-in
- URL: `/feed/sakuracon-2026`
- ✅ Verify: Accessible without login. Shows event info, vendor list. Mobile-friendly.

### 5. Try to access admin (negative test)
- URLs: `/admin`, `/vendor`, `/admin/events`
- ✅ Verify: All redirect to sign-in or show "not authorized". None return 500 or expose data.

---

## Cross-Cutting Checks

### Mobile (test at 375px / iPhone SE)
- [ ] No horizontal scroll on any public page
- [ ] Buttons are tappable (≥44px)
- [ ] Forms usable without zooming

### Error handling
- [ ] `/e/this-slug-does-not-exist` → clean 404, not 500
- [ ] `/join/fake-token-99999` → clean error page, not exception
- [ ] `/checkin/verify?token=bad&event=1&participant=1` → rejection message, not exception

### Pre-doors checklist (Jen, morning of April 3)
- [ ] `/admin/sidekiq` — queue depth 0, no Dead jobs
- [ ] Send one test broadcast to a real phone — confirm delivery
- [ ] Check Railway logs: `railway logs --tail 50` — no recurring errors
- [ ] Confirm Twilio account is upgraded to paid (trial = $12.16 remaining)
- [ ] Verify `APP_HOST` env var is set correctly in Railway

---

## Known Gaps / Open Items

| Item | Status | Notes |
|---|---|---|
| Twilio toll-free verification | ⏳ Pending | 5–15 business days. Reduced SMS functionality acceptable for this event. |
| Twilio trial → paid upgrade | 🔲 Todo | Must do before April 3 or volume SMS will fail |
| Sponsor logos (Aniplex, Kotobukiya, Kinokuniya, Huion, MAS Auth, IZE) | 🔲 Todo | Upload manually via /admin/sponsors |
| Guest photos | 🔲 Todo | Upload via /admin/guests if press photos obtained |
| Sponsor tier accuracy | ⚠️ Unconfirmed | Tiers estimated — confirm with SakuraCon before making public |
