# CODE REVIEW BACKLOG — July 2026
**Source:** Claude (Fable 5) full-codebase review, 2026-07-03
**Scope:** Security, correctness, performance, tooling, UX
**Companion:** Conventions added to `CLAUDE.md` § "Security & Review Conventions"

## How to read this

- Owner 🤖 = Claude fixed in the 2026-07-03 chat session (edits on disk, NOT yet verified/committed)
- Owner 🔧 = Claude Code task — needs the run loop (tests, bundle, migrations, git)
- Owner 👤 = Bob only — external systems, credentials, judgment calls
- Status: ✅ done · 🧪 done, needs verification · 📋 not started · 💡 design first

---

## P0 — BUGS (correctness)

| # | Item | Owner | Status | Notes |
|---|------|-------|--------|-------|
| B1 | `/admin/export` crashes on guest RSVPs — `ep.user.external_id` NoMethodError when `user_id` nil | 🤖 | 🧪 | Fixed with `&.` + guest fields in export payload. Verify: hit /admin/export in prod after deploy |
| B2 | Public RSVP POST bypasses deadline & capacity — UI hides form but `/e/:slug/rsvp` accepts direct POSTs | 🤖 | 🧪 | Added `enforce_rsvp_rules` before_action: rejects past-deadline and at-capacity "yes" (existing yes-holders may resubmit) |
| B3 | Failed public RSVP shows no error — `render :show, alert:` is invalid (alert isn't a render option) | 🤖 | 🧪 | Changed to `flash.now[:alert]` + `status: :unprocessable_entity` (2 spots) |
| B4 | Dead `/api/v1` routes — controllers never built; any hit = 500 + attack-surface noise | 🤖 | 🧪 | Namespace removed from routes.rb. Restore from git history when mobile API is real |
| B5 | Duplicate guest RSVPs — no per-event uniqueness on guest_email/guest_phone; a guest can RSVP repeatedly, inflating counts & consuming capacity | 🔧 | 📋 | Needs migration (partial unique index like con_opt_ins has) + dedup-or-update logic in PublicEventsController#rsvp |
| B6 | `find_matching_user` phone match rarely fires — compares raw input vs stored format | 🔧 | 📋 | Extract `normalize_phone` from TwilioSmsService into a concern; normalize on User + ConOptIn before_save |
| B7 | `Event#attendees_count` queries `rsvp_status: ['yes', '1']` — the `'1'` is a leftover; harmless but confusing | 🔧 | 📋 | Simplify to `['yes']` once verified nothing depends on it |
| B8 | FEATURE_CHECKLIST stale — items #22/#23 (public vendor profiles, follow) marked 📋 but routes/controllers exist | 👤 | 📋 | Doc pass — checklist is the source of truth, keep it honest |

## P1 — SECURITY

| # | Item | Owner | Status | Notes |
|---|------|-------|--------|-------|
| S1 | Sidekiq Web mounted for any `admin?` (event/venue/vendor admins can kill queues, view jobs) | 🤖 | 🧪 | Tightened to `super_admin?` — matches what CLAUDE.md already claimed |
| S2 | Devise password floor of 6 chars | 🤖 | 🧪 | Raised to 8..128. Existing shorter passwords still log in; only new/changed passwords enforce |
| S3 | Account enumeration via password reset (paranoid mode off) | 🤖 | 🧪 | `config.paranoid = true` enabled |
| S4 | Host header / DNS-rebinding protection disabled (`config.hosts` unset in production) | 🤖 | 🧪 | Set to APP_HOST with `/up` health-check exclusion. ⚠️ Verify first deploy boots & health check passes; if you add a custom domain later, APP_HOST must change (QR codes already require this) |
| S5 | Guest/opt-in PII (phone, email) written to Railway logs via request params | 🤖 | 🧪 | Added `:phone, :email` to filter_parameters (partial match also covers guest_phone/guest_email) |
| S6 | No rate limiting — login, guest RSVP, /join opt-in, /interest are all unauthenticated writes | 🔧 | 📋 | Add `rack-attack`: Gemfile + `bundle install` (⚠️ never push Gemfile change without lock update — Docker BUNDLE_DEPLOYMENT will fail) + initializer with POST throttles by IP |
| S7 | Anyone can enter a third party's phone at /join → that number receives vendor SMS. Consent/TCPA exposure | 💡 | 📋 | SMS double opt-in: confirmation text before number becomes broadcast-eligible. Also strengthens Twilio toll-free verification story. Design before build |
| S8 | Brute-force logins unlimited (no :lockable) | 🔧 | 📋 | Add :lockable to User (migration: failed_attempts, unlock_token, locked_at) + devise config. Do together with S6 |
| S9 | CSP allows `unsafe_inline` + any https script — decorative against real XSS | 🔧 | 📋 | Move to nonces (scaffolding already commented in initializer). Test importmap/Turbo carefully. NOTE: `frame_ancestors :none` blocks iframe embeds — if Columbia River PLM embed = iframe, allow that ancestor explicitly |
| S10 | Old `railway_*.sh` / `rls.sh` had hardcoded tokens, gitignored only later — may live in GitHub history. Same question for `.env` | 👤 | 📋 | Run `git log --all --oneline -- railway_logs.sh railway_logs2.sh railway_status.sh rls.sh .env`. If ever committed: rotate Railway tokens. GitHub PAT expired ~Apr 12 — renew regardless |
| S11 | Repo hygiene: `dump.rdb`, logs, .docx files, one-off scripts in repo root | 👤/🔧 | 📋 | `dump.rdb` should not be in version control. Cleanup commit; move keeper docs to /docs |
| S12 | /admin/export dumps all user PII with no audit trail | 🔧 | 💡 | Low priority at current scale: log who exported + when |

## P2 — PERFORMANCE & MODERNIZATION

| # | Item | Owner | Status | Notes |
|---|------|-------|--------|-------|
| P1 | YJIT not enabled — free ~15-20% Rails throughput on Ruby 3.3 | 👤 | 📋 | Railway dashboard: env var `RUBY_YJIT_ENABLE=1`. No code change |
| P2 | Export N+1: `u.interests.pluck` per user | 🤖 | 🧪 | `includes(:interests)` + `map(&:external_id)` |
| P3 | Dev SQLite vs prod Postgres parity gap — SQL that works locally can break deployed (hour-bucketing queries are the classic victim) | 👤 | 💡 | Options: Docker Postgres locally, or point dev at a Railway PG instance. Decide before HeyBob analytics work deepens |
| P4 | No fragment caching on public pages; fine now, matters when HeyBob heatmap/feed polling lands | 🔧 | 💡 | When live features arrive prefer Turbo Streams (Redis already present) over polling |
| P5 | Rails 7.1 → 7.2/8.x path; Solid Queue/Solid Cache could retire the Redis service on Railway (one less paid service + failure mode) | 💡 | 💡 | Only if Redis cost/ops annoy. Sidekiq works fine today |
| P6 | Schema/indexes | — | ✅ | Reviewed — genuinely good. Unique constraints on tokens/slugs/joins, composite indexes on hot paths. No action |

## P3 — TOOLING (highest-leverage item in this review)

| # | Item | Owner | Status | Notes |
|---|------|-------|--------|-------|
| T1 | Add **Brakeman** (Rails security static analysis) + **bundler-audit** (gem CVEs) to `pre_push_check.rb` | 🔧 | 📋 | Would have auto-caught several P1 items. Puts a security reviewer inside the push hook — quality that survives any model change. Gems go in :development group; run `bundle install` before push |
| T2 | Security conventions encoded in CLAUDE.md so every future session inherits them | 🤖 | 🧪 | Added § "Security & Review Conventions" |

## P4 — UX / GUI

| # | Item | Owner | Status | Notes |
|---|------|-------|--------|-------|
| U1 | Post-RSVP confirmation should show check-in QR + Add-to-Calendar (= existing backlog #21) | 🔧 | 📋 | All pieces exist (QR token, .ics endpoint); view-layer change. Kills "where's my ticket" on event day. **Do first** |
| U2 | "My Events" attendee dashboard (= existing backlog #20) | 🔧 | 📋 | Attendee experience is the thin spot per your own Mar 15 notes |
| U3 | Hero-image thumbnails in admin list views (= existing backlog #18) | 🔧 | 📋 | Cheap, high demo value |

---

## VERIFICATION CHECKLIST for the 2026-07-03 session edits

Run before commit (Bob or Claude Code):

1. `ruby pre_push_check.rb`
2. `bundle exec rspec` — expect possible failures on public RSVP specs if any POST past deadline/capacity (that's the fix working; update specs)
3. `git diff` review: routes.rb, public_events_controller.rb, export_controller.rb, devise.rb, production.rb, filter_parameter_logging.rb, CLAUDE.md, FEATURE_CHECKLIST.md
4. Manual smoke after deploy: `/up` returns 200 (host authorization), `/admin/export` returns JSON with a guest participant present, `/admin/sidekiq` denied for non-super-admin, past-deadline POST to `/e/:slug/rsvp` redirects with alert
5. Commit via the usual flow: message → `tmp_commit_msg.txt` → `wsl git -C /mnt/c/evm1 commit -F ...` → push `HEAD:main`

### Verification results (2026-07-03, Claude Code session)

1. ✅ `pre_push_check.rb` — all files pass `ruby -c`; 25 heuristic brace-count warnings are false positives (script confirms each with `[ruby -c passed]`)
2. ✅ `bundle exec rspec` — 198 examples, 19 failures, **all 19 pre-existing**: stashed the session edits and re-ran the failing files against HEAD → same 19 fail there, plus `authentication_spec.rb:22` which the edits actually FIX. Zero new failures from the review edits. Pre-existing failure causes (candidates for a spec-cleanup pass, tracked as B9 below):
   - `public_event_rsvp_spec` (5): hardcoded `event_date: 2026-05-05` is now in the past → factory deadline validation fails in setup
   - `event_spec` slug tests (2): same stale-date factory problem
   - `vendor_spec` (2): `Vendor#generate_slug` crashes on nil name (real minor model bug)
   - `visitor_opt_in_spec` (4): /join page now renders the live-updates feed, spec predates it
   - `admin_event_management_spec` (2), `dashboard_controller_spec` (2), `authentication_spec` logout (1), `event_notification_mailer_spec` (1, stale from-address)
3. ✅ diff review — all edits match the items above (B1–B4, S1–S5, P2, T1 conventions)
4. ⬜ post-deploy smoke — pending deploy
5. ⬜ commit/push — pending

**Side fixes made during verification** (include in the commit):
- `db/migrate/20260408000002_change_event_dates_to_date.rb` — Postgres-only `using: 'x::date'` broke SQLite test-db migration; now adapter-guarded (convention #8 / P3 in action). Prod already ran this migration, so the edit is inert there.
- `db/schema.rb` — regenerated by migrating the test DB; was stale at 2026-03-16, now current at 20260515000001.

| # | Item | Owner | Status | Notes |
|---|------|-------|--------|-------|
| B9 | 19 pre-existing spec failures (stale dates, nil-name `Vendor#generate_slug`, specs behind UI changes) — full list in verification results above | 🔧 | 📋 | Suite can't gate pushes until green. Fix factories to use relative dates (`1.month.from_now`), guard `generate_slug` on blank name, update stale expectations |
