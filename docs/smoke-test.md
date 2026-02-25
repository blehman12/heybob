# EVM1 Smoke Test Suite
**Trigger phrases:** `smoke test quick` or `smoke test full`

**Production URL:** https://heybob-production.up.railway.app
**Test account:** smoketest@heybob.app / Sm0keTest!

---

## Quick Mode — latest features only
Runs after each feature sprint. Checks only what was recently built.

| # | URL | Check |
|---|-----|-------|
| 1 | `/events` | Page loads, at least one event listed |
| 2 | `/events?tag=plm-tools-windchill` | "Filtered by: Windchill" badge shown, events listed |
| 3 | `/events?tag=nonexistent-tag` | No crash — filter silently ignored, all events shown |
| 4 | `/admin/events/sakuracon-2026-2026/cockpit` | Cockpit loads, shows 4 vendors, stat cards visible |
| 5 | `/admin/vendors/1` (CoreTech) | Vendor show page loads, no 500 (hero_image + Active Storage ok) |
| 6 | Vendor event edit | Edit a vendor event's booth/hall/load-in fields and save — metadata persists |
| 7 | Vendor onboarding checklist | Visit `/vendor/vendors/:id` — checklist visible, auto-hides when 4 items done |

---

## Full Mode — complete regression
Runs before Sakuracon or after any significant change.

### Public routes (no auth)
| # | URL | Check |
|---|-----|-------|
| 1 | `/events` | Events index loads, hosted events listed |
| 2 | `/events?tag=plm-tools-windchill` | Tag filter works, "Filtered by" shown |
| 3 | `/events?tag=nonexistent-tag` | No crash — filter silently ignored, all events shown |
| 4 | `/e/ptc-windchill-community-meetup-fall-2024-2026` | Event detail page loads (requires public_rsvp_enabled: true) |
| 5 | `/e/nonexistent-slug` | Redirects to root, not a 500 |
| 6 | `/` | Root loads (redirects to login or dashboard) |

### Auth protection checks (no login — should redirect, not 500)
| # | URL | Check |
|---|-----|-------|
| 7 | `/admin` | Redirects to login |
| 8 | `/admin/events` | Redirects to login |
| 9 | `/admin/categories` | Redirects to login |

### Authenticated routes (login as smoketest@heybob.app)
| # | URL | Check |
|---|-----|-------|
| 10 | Login | Signs in successfully, lands on dashboard |
| 11 | `/admin` | Admin dashboard loads |
| 12 | `/admin/events` | Events list loads |
| 13 | `/admin/categories` | Categories list loads |
| 14 | `/admin/users` | Users list loads |
| 15 | `/admin/venues` | Venues list loads |
| 16 | `/admin/export` | JSON export returns data |
| 17 | `/admin/vendors` | Vendors list loads, 4 vendors shown |
| 18 | `/admin/vendors/1` | CoreTech Solutions show page loads (Active Storage hero_image no 500) |
| 19 | `/admin/events/sakuracon-2026-2026/cockpit` | Event-Day Cockpit loads — 4 vendors in table, stat cards, check-in + broadcast panels |
| 20 | Vendor logistics edit | Edit CoreTech vendor event — set booth/hall/load-in date+time+notes, save — values persist on reload |
| 21 | Vendor onboarding checklist | Visit `/vendor` as vendor_admin user — checklist shows for incomplete vendor; completes and hides after all 4 items done |
| 22 | Vendor event QR token | Vendor event show page renders QR code (token not blank, /join/:token route resolves) |

---

## How to add new tests
When a new feature is built, add it to Quick mode first. After it's been stable for one session, move it to Full mode and remove from Quick.

---

## Known limitations
- Does not test RSVP submission flow (form POST)
- Does not test SMS broadcast send (Twilio side effects)
- Does not test check-in QR scan flow end-to-end
- Vendor onboarding checklist test (#21) requires logging in as a vendor_admin (vendor1@coretech.com / Vendor123!)
- These require more complex session/state management — manual for now
