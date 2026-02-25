# Shared Context — EVM1
> This file is maintained by the planning Claude (browser) after each conversation.
> Claude CLI reads it automatically on every `run-task` invocation.
> Last updated: 2026-02-25

---

## Project Snapshot
- **App**: HeyBob — Rails 7.1 event management (Sakuracon 2026 target)
- **Production**: https://heybob-production.up.railway.app
- **Deploy**: git push origin main → Railway auto-deploys (nixpacks)
- **DB**: PostgreSQL via Railway. Seed data live (1 venue, 1 event, 4 vendors)
- **Admin login**: admin@nwtg.com / Ch@ngeMe2026!

## Current Sprint Status
**Vendor Operations Layer — COMPLETE (Feb 24, 2026)**
- ✅ #5 Vendor event logistics (booth/hall/load-in edit form)
- ✅ #6 Vendor onboarding checklist
- ✅ #7 Event-day admin cockpit (/admin/events/:id/cockpit)
- ✅ #8 Admin vendor show/edit/new/import pages

**Backlog — next candidates:**
- #9 Event lifecycle status (draft/published/archived/cancelled)
- #10 Quick-add venue modal on event form
- #11 Vendor analytics
- #12 Rethink event date/time fields (schema change)

---

## Active Task
_(Planning Claude fills this in before each run-task invocation)_

**Status**: READY — awaiting run-task

**Task**: #9 Event lifecycle status (draft/published/archived/cancelled)

**Mode**: local first, then full

**Files likely touched**:
- db/migrate/[new migration file]
- app/models/event.rb
- app/controllers/admin/events_controller.rb
- app/helpers/application_helper.rb (or events_helper.rb)
- app/views/admin/events/index.html.erb
- app/views/admin/events/show.html.erb
- app/views/admin/events/_form.html.erb
- app/controllers/public_events_controller.rb
- config/routes.rb
- spec/models/event_spec.rb

---

## Decisions Made This Session
_(Running log — planning Claude appends here during conversation)_

- 2026-02-25: Established three-entity workflow (user ↔ planning Claude ↔ Claude CLI)
- 2026-02-25: Defined three deploy modes: local (no push), light (push), full (push + smoke test)
- 2026-02-25: Claude CLI runs from WSL at /mnt/c/evm1 with --dangerouslySkipPermissions
- 2026-02-25: Decided to reduce Railway deploys — use local/light for iteration, full only for features

---

## Recently Completed Work
_(Planning Claude updates after each successful task)_

- b4331cc — Fix export 500 and update smoke test doc
- e415d86 — Fix cockpit route helper
- b43bb8e — Fix cockpit 500
- 587637f — Add seed migration for vendor events at Sakuracon 2026
- a57d854 — Add bootstrap migration (seed admin + smoketest users)

---

## Known Gotchas for Claude CLI
- Ruby is in WSL only — not available in Windows Git Bash
- Event form has TWO input[name="event[event_date]"] fields (duplicate bug, known)
- seeds.rb has `return if Rails.env.production?` guard — safe to run locally
- Pre-push hook warns "ruby not found" — false positive in Windows context, ignore
- VendorEvent metadata is JSON — always use extract_metadata() pattern, never overwrite whole field
- Admin::VendorsController find_or_create_owner fails silently on unknown email (User needs phone+company)
- Vendor namespace uses shallow: true — vendor_event routes don't need vendor_id prefix
- routes.rb admin namespace starts ~line 74, indentation is messy

---

## Key File Locations
- Routes:              config/routes.rb
- Admin events ctrl:   app/controllers/admin/events_controller.rb
- Vendor event ctrl:   app/controllers/vendor/vendor_events_controller.rb
- Cockpit view:        app/views/admin/events/cockpit.html.erb
- Vendor event show:   app/views/vendor/vendor_events/show.html.erb
- Task file:           .claude/task.md
- Mode files:          .claude/modes/{local,light,full}.md
- This file:           .claude/context.md
