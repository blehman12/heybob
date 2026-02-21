# EVM1 — Vendor & Attendee Experience Design Document

**Created:** February 21, 2026  
**Status:** Active — Pre-build brainstorm, Sakuracon MVP  
**Working Principle:** Design to the 80%. Note corner cases, don't build to them. Get MVP out the door.

---

## 1. The Problem We Are Solving

Attendees go to events — conferences, conventions, boat parties — and leave without
connecting with the people they should have met. The existing app manages events from
the admin side but does nothing for the attendee once they RSVP.

Vendors at large cons (Sakuracon, etc.) have a related but distinct problem: someone
visits their booth, there is a moment of connection, and it evaporates. No follow-up,
no way to reach that person again, no way to amplify time-sensitive moments
(drawings, specials, panel appearances) beyond whoever is physically nearby.

**The core insight:** Both problems are the same thing at different scales —
a fleeting moment of connection that needs a bridge to something lasting.

---

## 2. Real-World Test Cases

### Inland Chief (Bob's tugboat)
- Smaller, intimate gatherings
- Host wants to broadcast moments in real time ("food is out", "engine demo in 10 min")
- Attendees may know some people and miss others they should connect with
- Connection problem: people in the same space leave without meeting

### Sakuracon 2026 — Easter Weekend (April 3)
- Large convention, hundreds of booths, chaotic environment
- **Portland KPOP CO** is the primary guinea pig vendor — motivated, real testers
- Additional vendors willing to participate
- Con floor has poor cellular reception — concrete, steel, carrier congestion
- Connection problem: visitor walks past booth, moment evaporates

**These two contexts share the same underlying architecture.
The difference is scale and the role of the vendor.**

---

## 3. The Unified Concept

### One Scan, Two Things Happen

A visitor scans a vendor's QR code at their booth:

1. **They opt into the con-wide feed** — they see live updates from ALL participating
   vendors at the con. One unified experience, no app switching.

2. **They are associated with that specific vendor** — the vendor knows this person
   visited their booth and can target post-con follow-up specifically to their visitors.

The visitor makes no choices and understands none of this architecture.
They scan, enter name + phone/email (20 seconds), done.

### The Live Discovery Feed

A public, real-time feed scoped to the event showing what vendors are doing *right now*:

> 🎵 Portland KPOP CO — "Drawing for limited sticker pack in 15 min! Booth 247"  
> 🎨 Sakura Prints — "Just restocked holographic prints"  
> 🎮 Retro Game Vault — "Tournament running now, winner gets store credit"

- Accessible via public URL — no login required
- QR code at con entrance or on program points here
- Vendors who post get foot traffic spikes
- Turns passive booth-sitting into active broadcasting
- Scales down to Inland Chief naturally (host posts "food is out")

### The Value Exchange (Why Visitors Scan)

- Free sticker with signup (KPOP CO's natural offering)
- Entry into drawing
- Access to live vendor updates and specials during the con
- Post-con follow-up from vendors they actually visited

---

## 4. Communication Strategy

### During-Con: SMS Broadcasts
- Vendor posts a message → all opted-in visitors receive SMS
- SMS chosen over push notifications because:
  - Store-and-forward — queues and delivers when signal returns
  - More reliable than push in dead zones (convention halls)
  - No app install required
- **Caveat:** Time-sensitive messages ("drawing in 15 min") vulnerable to delivery delay
  in congested areas. Vendors should be aware.
- **Provider:** Twilio (~$0.008/SMS)
- **Cost estimate for Sakuracon MVP:** 500 opt-ins × 5 broadcasts = ~$20

### Post-Con: Email Campaigns
- Vendor sends to their specific booth visitors (not all con opt-ins)
- Leverages existing email infrastructure in app
- "Thanks for stopping by, here's what we have coming up"
- Hooks into future email campaign feature

### Future: In-App Messaging
- If visitors bookmark the PWA or return to the feed URL
- Extends the channel beyond SMS/email
- Deferred — not Sakuracon MVP scope

---

## 5. Visitor Experience Design

### The Opt-In Screen (First Screen After QR Scan)

**Design principle: One thumb, five seconds.**
Everything the visitor does must work standing up, in a noisy hall,
on a phone screen, with one hand.

**Layout:**
```
┌─────────────────────────┐
│                         │
│   [vendor hero image    │
│    top 40% of screen]   │
│                         │
├─────────────────────────┤
│  Portland KPOP CO       │  ← vendor name, bold
│  Sakuracon 2026         │  ← con context, small/muted
│                         │
│  "Free sticker with     │  ← vendor's own hook text
│   signup + enter our    │    (vendor writes this)
│   drawing!"             │
│                         │
│  ┌───────────────────┐  │
│  │ Your name         │  │
│  └───────────────────┘  │
│  ┌───────────────────┐  │
│  │ Phone or email    │  │
│  └───────────────────┘  │
│                         │
│  [  COUNT ME IN  ]      │  ← big, full width, exciting
│                         │
│  You'll get live        │  ← tiny, friendly, honest
│  updates from all       │
│  Sakuracon vendors      │
└─────────────────────────┘
```

**Key decisions:**
- Lead with vendor brand, not generic app UI
- "Count Me In" not "Submit" — joins something exciting
- Fine print sets honest expectation about con-wide opt-in
- Vendor provides: one image + one line of hook text (that's it)

### Progressive Web App
- No app store friction
- Visitor scans → browser opens → works immediately
- "Add to home screen" available but not required
- Offline-capable for feed (cached content shows in dead zones)
- Mobile-first design throughout

---

## 6. Vendor Experience Design

### Vendor Dashboard (Simple)
- Opt-in count for this event (big number, front and center)
- Broadcast composer: one text field, one send button
- Preview of how many people will receive the message
- Their QR code (downloadable for printing)
- Recent broadcast history

### Vendor Onboarding Per Event
- Enter booth number / location (flexible metadata, see data model)
- Upload hero image
- Write hook line
- Download QR code for table display

**Vendor forgiveness principle:** Vendors are motivated users who understand
they're early testers. UI can be functional before it's beautiful.
Visitor experience gets the polish first.

---

## 7. Data Model

### Design Principles
- Vendor is master, con participation is detail (master/detail pattern)
- One User record can wear multiple hats (vendor owner, attendee, admin)
- Build join tables for flexibility, skip premature attribute columns
- 80% design — corner cases noted, not built to yet

### Core New Models

```
Vendor  (master — exists independent of any specific con)
  belongs_to :user  (owner)
  has_many :vendor_users
  has_many :vendor_events
  name:         string
  description:  text
  hero_image:   (Active Storage attachment)
  hook_line:    string
  website:      string

VendorUser  (who can manage this vendor — simple, no roles yet)
  vendor_id:    integer
  user_id:      integer
  added_at:     datetime
  # Corner case noted: roles within vendor team (owner vs helper) — deferred

VendorEvent  (detail — vendor's participation in one specific con)
  belongs_to :vendor
  belongs_to :event
  metadata:     jsonb    # booth_number, hall, table, etc. — flexible per con
  qr_token:     string   # unique per vendor per event
  is_active:    boolean
  display_order: integer

ConOptIn  (a visitor who scanned in — may not have a User account)
  belongs_to :event
  belongs_to :vendor_event  # first scan / referring vendor
  name:         string
  phone:        string
  email:        string
  opted_in_at:  datetime
  user_id:      integer (nullable — if they happen to have an account)
  # Deduplication: same phone = same person, one record per phone per event

VendorOptIn  (join — handles visitor scanning at multiple booths)
  vendor_event_id:  integer
  con_opt_in_id:    integer
  scanned_at:       datetime

Broadcast  (a message sent by a vendor)
  belongs_to :vendor_event
  message:          string
  channel:          enum  (sms, email, feed)
  scope:            enum  (booth_visitors, entire_con)
  sent_at:          datetime
  recipient_count:  integer  (snapshot at send time)

BroadcastReceipt  (delivery tracking per recipient)
  broadcast_id:   integer
  con_opt_in_id:  integer
  status:         enum  (pending, delivered, failed)
  delivered_at:   datetime
```

### Integration with Existing Models

```
User           → bridge between existing app users and vendor owners
Event          → the con (Sakuracon 2026) — existing model, no changes
EventParticipant → existing model unchanged, vendors can still be
                   EventParticipants for event management purposes
```

### Corner Cases Noted (Not Built Yet)
- Multi-user vendor teams with role-based permissions
- Visitor deduplication across cons (same person at Sakuracon and Kumoricon)
- Con organizer configuring required metadata fields per event
- Visitor account creation / upgrade from anonymous opt-in to full User
- Data export / retention policy per vendor

---

## 8. Sakuracon MVP Scope

### Must Work Perfectly
- [ ] Vendor QR code generation per event
- [ ] Visitor opt-in flow — mobile-first, 20 seconds, no friction
- [ ] Con-wide opt-in (scan any vendor, join the whole con)
- [ ] Vendor association tracking (which booth did they scan at)
- [ ] Vendor broadcast via SMS (Twilio)
- [ ] Public live feed URL (no login required)
- [ ] Vendor dashboard: opt-in count + send broadcast

### Explicitly Deferred (Not Sakuracon MVP)
- Native app / app store presence
- Push notifications
- Analytics dashboard
- Vendor billing / payment
- Multi-user vendor teams
- Post-con email campaign UI (hooks exist, UI deferred)
- In-app messaging

---

## 9. Build Sequence

### Weeks 1–2: Foundation
- Migrations: Vendor, VendorUser, VendorEvent, ConOptIn, VendorOptIn
- Vendor registration and event association
- QR token generation per VendorEvent
- Visitor opt-in landing page (shell — mobile-first, vendor-branded)

### Weeks 3–4: Communication Layer
- Twilio SMS integration (riskiest piece — done early)
- Vendor broadcast interface
- BroadcastReceipt tracking
- Public live feed (read-only, no login)

### Weeks 5–6: Polish and Testing
- Real KPOP CO content (image + hook line)
- End-to-end testing on real phones
- PWA manifest + service worker
- Mobile UX polish
- Edge cases and error states

**Key dependency:** KPOP CO needs the vendor interface at least 1 week before
the con to get comfortable. Target: vendor interface ready by March 27.

---

## 10. KPOP CO Vendor Setup Checklist

- [ ] Hero image (initial placeholder → refined image by Week 3)
- [ ] Hook line text (e.g., "Free sticker with signup + enter our drawing!")
- [ ] Booth number (available closer to con date)
- [ ] Phone number for Twilio test messages
- [ ] Designate 1-2 people who will manage broadcasts during the con

---

## 11. Future Considerations (Post-Sakuracon)

- **Platform business model:** Vendors pay per event, cons pay for organizer features,
  aggregate foot traffic data as a paid analytics tier
- **Cross-con vendor history:** KPOP CO sees opt-in counts across all cons they've attended
- **Visitor discovery:** "Who else is coming?" attendee-facing view before the event
- **Lockable Devise:** Brute force protection before email campaigns scale
- **Con organizer role:** Separate from admin — manages their specific event only
- **Vendor roles:** Owner vs helper permissions within a vendor team

---

*This document lives at `/docs/SAKURACON_MVP_DESIGN.md` in the evm1 repository.
Update it as decisions are made and scope changes.*
