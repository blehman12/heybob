# evm1 Refactoring Analysis
**Date:** February 22, 2026  
**Scope:** Codebase review for tech debt and improvement opportunities

Rated by: **Impact** (what you get) and **Risk** (what could break).
Do/Don't decisions are recommendations, not mandates.

---

## 1. RsvpController vs PublicEventsController — Duplicate RSVP Logic

**What's wrong:** Two controllers handle RSVP flow. `RsvpController` is the older internal one (authenticated, event_id param). `PublicEventsController` has a newer, better `rsvp` action (public + guest-capable). They have overlapping but diverging logic — deadline checking, find-or-create participant, status validation.

**Risk of leaving it:** As RSVP features evolve you'll fix bugs in one place and forget the other. Already happening — `RsvpController#update` checks deadline manually with a string comparison; `PublicEventsController` doesn't.

**Refactor:** Extract an `RsvpService` class that both controllers call. ~50 lines. Controllers become thin wrappers.

**Impact:** Medium. **Risk:** Low — pure extraction, no behavior change. **Recommendation: Do it before adding more RSVP features.**

---

## 2. EventParticipant#qr_code_data — Hardcoded localhost

**What's wrong:** `qr_code_data` method has hardcoded `host = 'localhost:3000'` with commented-out alternatives. In production on Railway the QR codes point to localhost, which means check-in QR scanning is broken in production.

```ruby
host = 'localhost:3000'  # <-- this is in production right now
```

**Refactor:** Use `Rails.application.routes.default_url_options[:host]` or an ENV variable (`APP_HOST`). One line fix.

**Impact:** High — QR check-in is actually broken in production right now. **Risk:** None. **Recommendation: Fix immediately.**

---

## 3. Event#public_url — Same localhost problem

Same issue as above. The `public_url` method returns `http://localhost:3000/e/#{slug}` in all environments with a comment saying "for production use routes helper."

**Refactor:** Use `Rails.application.routes.url_helpers` with proper host config.

**Impact:** Medium (affects any email or export that includes event links). **Risk:** None. **Recommendation: Fix with #2 above, same PR.**

---

## 4. Admin::EventsController#load_users — Wrong scope

**What's wrong:** `load_users` fetches only `role: 'attendee'` users for participant dropdowns. Now that you have `event_admin`, `venue_admin`, `vendor_admin` roles, those users can't be added as participants to events through the UI even though they should be able to attend.

```ruby
def load_users
  @users = User.where(role: 'attendee').order(:first_name, :last_name)
end
```

**Refactor:** `User.order(:first_name, :last_name)` — all users are valid participants.

**Impact:** Low now (few non-attendee users), but will bite you as you add staff accounts. **Risk:** None. **Recommendation: One-line fix, do it now.**

---

## 5. EventParticipant#rsvp_status_text — Redundant with enum

**What's wrong:** `rsvp_status_text` does a manual `case` switch on string/integer values to return display strings. Rails enums already give you `.humanize` and the `rsvp_status_display` method above it also exists and does the same thing differently.

Three methods doing overlapping jobs: `rsvp_status`, `rsvp_status_display`, `rsvp_status_text`.

**Refactor:** Delete `rsvp_status_text`, use `rsvp_status.humanize` or a single `status_label` method everywhere.

**Impact:** Low. **Risk:** Low — search views for `rsvp_status_text` calls first. **Recommendation: Cleanup when you're in that file for another reason.**

---

## 6. Slug Generation — Potential Infinite Loop

**What's wrong:** `Event#generate_slug` has a loop that increments a counter until it finds a unique slug. If something goes very wrong (e.g., DB error on the existence check), it loops forever.

```ruby
loop do
  new_slug = "#{candidate_slug}-#{counter}"
  break self.slug = new_slug unless Event.where(slug: new_slug).exists?
  counter += 1
end
```

**Refactor:** Add a `counter < 100` guard and raise if exceeded. Or better, append the `external_id` fragment as the uniqueness suffix — guaranteed unique by definition.

**Impact:** Low probability, catastrophic if hit. **Risk:** Low to fix. **Recommendation: Add the guard. 2-line fix.**

---

## 7. TwilioSmsService — Good, Leave Alone

Deliberately calling this out: `TwilioSmsService` is well-structured. Single responsibility, Result struct, proper error handling, credential fallback chain. Don't touch it.

---

## 8. Model Fat vs Service Layer — Watch This

**Current state:** Event and EventParticipant models are getting chunky (122 and 172 lines respectively). Still manageable. The concerns pattern (`HasExternalId`) is already in place which is the right direction.

**Watch for:** When a model method starts needing another model to do its work (e.g., "create a participant and send an email and log an audit"), that's a service object. You're not there yet but slug generation, QR token generation, and check-in logic are all borderline.

**Recommendation: No action now. Reassess when either model hits ~250 lines or when you find yourself calling `require` in a model.**

---

## 9. Missing `public_rsvp_enabled` Filter in Export

Minor: the export controller includes all events regardless of `public_rsvp_enabled` status. That's probably correct (you want a complete export), but worth confirming the intent. If you ever add a `draft` event status, you'll want to decide whether drafts export.

**Recommendation: Backlog item — revisit when visibility/status enum is added.**

---

## Priority Order

| # | Item | Effort | Do When |
|---|------|--------|---------|
| 1 | Fix `qr_code_data` hardcoded localhost | 30 min | Now |
| 2 | Fix `Event#public_url` same issue | 15 min | Same PR |
| 3 | Fix `load_users` attendee-only scope | 5 min | Now |
| 4 | Add slug loop guard | 10 min | Now |
| 5 | Extract RsvpService | 2 hrs | Before next RSVP feature |
| 6 | Clean up rsvp_status_text duplication | 30 min | Next time in that file |
| 7 | Revisit export for draft events | — | When status enum added |
