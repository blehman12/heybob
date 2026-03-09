# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

# Event Management System (EVM1) Architecture Guide

## Overview
This is a Ruby on Rails 7.1 event management application that handles event creation, RSVP management, participant check-in, vendor management, and SMS broadcast campaigns. The system supports multiple user roles with different permission levels and includes features for public event pages, mobile-friendly check-in flows, and vendor opt-in campaigns.

**Tech Stack**: Rails 7.1 | Ruby 3.3.3 | PostgreSQL | Sidekiq | Redis | Twilio SMS | Devise | Bootstrap 5

---

## Essential Development Commands

### Setup & Installation
```bash
# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate

# Seed data (categories taxonomy)
rails runner db/seeds/categories.rb

# Optional: Seed example categorizations
rails runner db/seeds/categorizations.rb
```

### Running the Application

**Option 1: Using Foreman (Recommended)**
```bash
# Install foreman if needed
gem install foreman

# Start all services (Rails + Sidekiq + Redis)
foreman start -f Procfile.dev
```

**Option 2: Manual (Separate Terminals)**
```bash
# Terminal 1: Rails server
rails server

# Terminal 2: Sidekiq (background jobs)
bundle exec sidekiq

# Note: Redis must be running separately
```

**Option 3: Windows PowerShell**
```powershell
.\start_dev.ps1
```

### Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/event_spec.rb

# Run specific test by line number
bundle exec rspec spec/models/event_spec.rb:42

# Run tests with documentation format
bundle exec rspec --format documentation

# Run tests for a specific controller
bundle exec rspec spec/controllers/public_events_controller_spec.rb

# Run system tests (full integration)
bundle exec rspec spec/system/

# Setup test database
RAILS_ENV=test bundle exec rails db:migrate
```

### Database Operations

```bash
# Create migration
rails generate migration MigrationName

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Reset database (drop, create, migrate, seed)
rails db:reset

# Check migration status
rails db:migrate:status

# Access Rails console
rails console

# Access database console
rails dbconsole
```

### Code Generation

```bash
# Generate model
rails generate model ModelName field:type

# Generate controller
rails generate controller ControllerName action1 action2

# Generate migration
rails generate migration AddFieldToModel field:type

# Generate mailer
rails generate mailer MailerName
```

### Background Jobs & Queue Management

```bash
# Start Sidekiq with config
bundle exec sidekiq -C config/sidekiq.yml

# Monitor Sidekiq
# Visit http://localhost:3000/admin/sidekiq (requires super_admin)

# Clear all Redis keys (use with caution)
redis-cli FLUSHALL
```

### Utilities & Maintenance

```bash
# Lint/format code (if configured)
bundle exec rubocop

# Check routes
rails routes

# Find specific route
rails routes | grep events

# Clear logs
rake log:clear

# Clear tmp files
rake tmp:clear

# Assets precompile (production)
rails assets:precompile
```

---

## Core Domain Models & Relationships

### 1. User Model
**Role**: Central user entity with role-based access control
**Path**: `/app/models/user.rb`

**Roles** (enum):
- `attendee` (0) - Default, can RSVP to events
- `super_admin` (1) - Full system access
- `event_admin` (2) - Manage events and assign categories
- `venue_admin` (3) - Manage venues
- `vendor_admin` (4) - Manage vendors

**Key Associations**:
```
has_many :event_participants      # Direct participation records
has_many :events (through)        # Events user participates in
has_many :created_events          # Events created by this user (creator_id)
has_many :vendor_events           # Events where user is vendor (filtered through event_participants)
has_many :categorizations         # User's interests/categories
has_many :interests (through)     # Categories user is interested in
```

**Key Methods**:
- `full_name` - Returns formatted name
- `admin?` - Check if any elevated role
- `can_manage_events?` - Permission check (super_admin or event_admin)
- `can_manage_venues?` - Permission check
- `can_manage_vendors?` - Permission check
- `participant_for_event(event)` - Get EventParticipant record for event
- `rsvp_status_for_event(event)` - Get RSVP status ('yes', 'no', 'maybe', 'pending')
- `checked_in_for_event?(event)` - Check-in status query

**Validations**:
- Presence: first_name, last_name, phone, company
- Cannot demote last super_admin
- Cannot self-demote your own super_admin role

---

### 2. Event Model
**Role**: Core event entity with multiple event types
**Path**: `/app/models/event.rb`

**Event Types** (enum):
- `hosted` (0) - Full RSVP, check-in, vendor capability
- `participating` (1) - External event with our presence (booth, sponsor, speaker)
- `reference` (2) - External event, awareness only

**Key Associations**:
```
belongs_to :venue (optional)
belongs_to :creator (class_name: 'User')
has_many :event_participants      # All RSVPs
has_many :users (through)
has_many :vendor_events           # Vendor booth records
has_many :vendors (filtered)       # Users with vendor role at this event
has_many :organizers (filtered)    # Users with organizer role at this event
has_many :con_opt_ins             # Visitor opt-ins for broadcasts
has_many :categorizations         # Event categories/tags
has_many :categories (through)
```

**Key Methods**:
- `rsvp_available?` - hosted? && rsvp_open?
- `attendees_count` - Count of confirmed RSVPs
- `vendors_count` - Count of vendors
- `rsvp_open?` - Check if before deadline
- `spots_remaining` - Max attendees - confirmed count
- `days_until_deadline` - Days left for RSVP
- `add_participant(user, role: :attendee)` - Create EventParticipant record
- `public_url` - Generate shareable URL (uses slug)
- `to_param` - Use slug for routing

**Validations**:
- Presence: name, event_date, max_attendees
- RSVP deadline before event date
- external_url required if participating or reference type
- Custom questions stored as JSON array

**Callbacks**:
- `before_save`: ensure_custom_questions_array
- `before_validation`: generate_slug (from name + year)

---

### 3. EventParticipant Model
**Role**: Join table with rich RSVP and check-in data
**Path**: `/app/models/event_participant.rb`

**Enums**:
- `role`: attendee (0), vendor (1), organizer (2)
- `rsvp_status`: pending (0), yes (1), no (2), maybe (3)
- `check_in_method`: qr_code (0), manual (1), bulk (2)

**Key Associations**:
```
belongs_to :user (optional)          # Made optional for guest RSVPs
belongs_to :event
belongs_to :checked_in_by (class_name: 'User', optional)
```

**Key Methods**:
- `checked_in?` - Presence of checked_in_at
- `check_in!(method: :qr_code, checked_in_by: nil)` - Perform check-in
- `undo_checkin!` - Clear check-in data
- `generate_qr_code_token` - Create unique secure token
- `qr_code_data` - Generate full QR code URL
- `display_name` / `display_email` / `display_phone` - Guest or user data
- `rsvp_status_text` / `rsvp_status_display` - Human-readable status
- `has_custom_answers?` - Check if RSVP answers provided
- `check_in_status_text` / `check_in_method_text` - Display methods

**Guest Support**:
- `is_guest` boolean field
- `guest_name`, `guest_email`, `guest_phone` fields
- Validation: must have either user_id or guest_name
- Email format validation for guests

**Serialization**:
- `rsvp_answers` stored as JSON (custom form responses)

**Callbacks**:
- `before_save`: ensure_rsvp_answers_hash
- `after_create`: generate_qr_code_token

---

### 4. Vendor Model
**Role**: Vendor entity for booth/artist presence management
**Path**: `/app/models/vendor.rb`

**Participant Types** (enum):
- `business` (0) - Dealer's room / commercial vendor
- `artist` (1) - Artist Alley / individual creator

**Key Associations**:
```
belongs_to :user              # Owner
has_many :vendor_users        # Additional users who can access vendor
has_many :users (through)
has_many :vendor_events       # Presence at specific events
has_many :events (through)
has_one_attached :hero_image  # Active Storage
has_many :categorizations     # Vendor categories
has_many :categories (through)
```

**Key Methods**:
- `accessible_by?(user)` - Check access permission
- `artist?` - Type check
- `social_handles` - Hash of social media handles
- `primary_web_presence` - Website or social handle for display

---

### 5. VendorEvent Model
**Role**: Bridge between Vendor and Event with QR opt-in flow
**Path**: `/app/models/vendor_event.rb`

**Category Enum**:
- `dealer` (0), `artist_alley` (1), `sponsor` (2), `exhibitor` (3), `panelist` (4)

**Key Associations**:
```
belongs_to :vendor
belongs_to :event
has_many :vendor_opt_ins       # Visitor relationships
has_many :con_opt_ins (through)
has_many :broadcasts           # SMS broadcasts from this vendor
```

**QR Token**:
- Unique, secure token generated on create
- Maps to `/join/:qr_token` public route
- Used for visitor opt-in campaigns

**Metadata**:
- Stored as JSON
- Contains booth_number, hall, etc.

**Key Methods**:
- `booth_number` / `hall` - Extract from metadata
- `opt_in_count` - Number of visitors who opted in
- `category_label` - Human-friendly category name
- `optin_headline` / `optin_subtext` - Custom copy for QR landing page

---

### 6. Category Model
**Role**: Hierarchical taxonomy system with 5 facets
**Path**: `/app/models/category.rb`
**Reference**: See `docs/TAXONOMY.md` for complete taxonomy documentation

**Facets** (enum):
- `domain` (0) - PLM, CAD, specific software (e.g., Windchill, Creo, SAP)
- `format` (1) - conference, user group, training, meetup, trade show, convention, webinar
- `geography` (2) - Geographic region (e.g., Pacific Northwest, North America, Virtual)
- `fandom` (3) - anime, gaming, comic, pop culture, tabletop
- `audience` (4) - engineers, managers, IT, executives, other

**Structure**:
- Parent/child hierarchy (max 2 levels)
- Only `domain` facet has parent/child structure; other facets are flat
- One parent can have multiple children
- Child must share parent's facet
- Slug generation: root = `name.parameterize`, child = `"#{parent.slug}-#{name.parameterize}"`

**Example Hierarchy** (domain facet only):
```
PLM Tools (plm-tools)
  ├─ Windchill (plm-tools-windchill)
  ├─ Creo (plm-tools-creo)
  └─ Arena (plm-tools-arena)
ERP / MES (erp-mes)
  ├─ SAP (erp-mes-sap)
  └─ Oracle (erp-mes-oracle)
```

**Key Methods**:
- `full_name` - "Parent > Child" or just name
- `root?` - Check if no parent
- `grouped_for_select` - Returns categories grouped by facet for dropdowns
- `Category.active.for_facet(:domain).ordered` - Get categories for a specific facet

**Usage Examples**:
```ruby
# Tag an event with multiple facets
event.categories << Category.find_by(slug: 'plm-tools-windchill')  # domain
event.categories << Category.find_by(slug: 'user-group')           # format
event.categories << Category.find_by(slug: 'pacific-northwest')    # geography

# Query events by category
cat = Category.find_by(slug: 'windchill')
Event.joins(:categorizations).where(categorizations: { category: cat })
```

---

### 7. Venue Model
**Role**: Physical location management
**Path**: `/app/models/venue.rb`

**Key Associations**:
```
has_many :events
```

**Key Methods**:
- `full_address` - Formatted address
- `events_count` - Total events
- `upcoming_events` - Events on or after current date

**Scopes**:
- `available_for_date(date)` - Venues not booked on that date

---

### 8. ConOptIn Model
**Role**: Visitor opt-in records for broadcast communications
**Path**: `/app/models/con_opt_in.rb`

**Purpose**: Track visitors who opt-in to communications at an event (typically via QR code at vendor booth)

**Key Associations**:
```
belongs_to :event
belongs_to :vendor_event         # The vendor they first interacted with
belongs_to :user (optional)      # nil for anonymous visitors
has_many :vendor_opt_ins         # Many-to-many to other vendors
has_many :vendor_events (through)
has_many :broadcast_receipts     # SMS delivery records
```

**Key Fields**:
- `name`, `phone`, `email` - Visitor contact info
- `opted_in_at` - Timestamp of opt-in
- `visitor_type` - Type classification

**Validations**:
- Requires at least phone or email
- Phone and email must be unique per event
- Email format validation

---

### 9. Broadcast & BroadcastReceipt Models
**Role**: SMS broadcast campaign system
**Paths**: `/app/models/broadcast.rb`, `/app/models/broadcast_receipt.rb`

**Broadcast**:
- Channels: sms, email, feed
- Scope: booth_visitors (just this vendor's opt-ins) or entire_con (all event opt-ins)
- Message: max 160 chars for SMS
- Status: pending or sent

**BroadcastReceipt**:
- Status: pending, delivered, failed
- Links broadcast to individual con_opt_in recipients
- Delivery tracking via Twilio message SID

---

### 10. Supporting Models
- **Categorization**: Join table for categorizing events, vendors, and users
- **VendorUser**: Join table for additional vendor access (shared account)
- **VendorOptIn**: Join table linking ConOptIn to multiple VendorEvents

---

## Controller Organization

### Authentication & Authorization Pattern
- **Admin::BaseController**: Base for all admin controllers
  - `before_action :authenticate_user!`
  - `before_action :ensure_admin!`
  - Helper methods: `ensure_super_admin!`, `ensure_can_manage_events!`, etc.

### Public Controllers (No Auth Required)
1. **PublicEventsController** (`/app/controllers/public_events_controller.rb`)
   - Routes: `/e/:slug`, `/e/:slug/rsvp`, `/e/:slug/confirmation`, `/e/:slug/calendar`
   - Features: Public RSVP, guest RSVP, iCalendar export
   - Checks: `public_rsvp_enabled?` flag on event

2. **CheckinController** (`/app/controllers/checkin_controller.rb`)
   - Routes: `/checkin`, `/checkin/scan`, `/checkin/manual`, `/checkin/verify`, `/checkin/process`
   - Features: QR code verification, manual check-in, success confirmation
   - Uses QR tokens from EventParticipant for security

3. **VisitorOptInsController** (`/app/controllers/visitor_opt_ins_controller.rb`)
   - Routes: `/join/:qr_token` (vendor booth QR code landing)
   - Workflow: Scan QR → Opt-in → Welcome → Event feed

### Authenticated Controllers

4. **RsvpController** (`/app/controllers/rsvp_controller.rb`)
   - Routes: `/rsvp/:event_id`, `/rsvp/:status`
   - Actions: show (view), update (submit RSVP)
   - Features: Custom RSVP answers, email notifications, deadline checks

5. **DashboardController** (Main user dashboard)
   - Route: `/` (root), `/dashboard`
   - Shows: Upcoming events, user RSVPs, quick actions

6. **UsersController** (User profile management)
   - Routes: `/profile/edit`, `/profile`
   - Features: Profile editing, user settings

### Admin Namespace (`/admin/...`)
Protected by `Admin::BaseController` with role checks.

7. **Admin::EventsController**
   - Full CRUD for events
   - Participants view with split by role (organizers, vendors, attendees)
   - Actions:
     - `index` - List all events (paginated, eager loaded)
     - `show` - Event details with participant statistics
     - `new/create` - Create new event
     - `edit/update` - Modify event
     - `destroy` - Delete event
     - `participants` - Manage participants for event
     - `add_participant` - Add single participant
     - `bulk_invite` - Invite multiple users (sends email)
     - `export_participants` - CSV export
   - Strong params: name, description, event_type, venue, dates, max_attendees, categories

8. **Admin::VenuesController**
   - Full CRUD: create, read, update, delete
   - Bulk operations: import CSV, export CSV, bulk delete, bulk archive
   - Relations: List events using each venue

9. **Admin::VendorsController**
   - Full CRUD for vendors
   - Bulk operations: import CSV, export CSV
   - Relations: List events, users associated

10. **Admin::UsersController**
    - Full CRUD for users
    - Role management with permission checks
    - Bulk operations: create, invite, delete via CSV
    - Scopes: filter by admin type, attendees-only
    - Admin safety: Cannot demote last super_admin

11. **Admin::CategoriesController**
    - Create and manage taxonomy
    - Validation: Parent/child relationship, facet restrictions

12. **Admin::CheckinController**
    - Check-in dashboard per event
    - Bulk check-in operations
    - QR code printing/badge generation
    - Export checked-in participants

13. **Admin::ExportController**
    - Data export (super_admin only)
    - Reports and analytics

14. **Admin::ParticipantsController**
    - Global view of all event participants across all events

15. **Admin::DashboardController**
    - Admin overview: event counts, user stats, participant summaries

### Vendor Namespace (`/vendor/...`)
Protected by `Vendor::BaseController` with vendor access checks.

16. **Vendor::DashboardController**
    - Vendor overview
    - List of events they're participating in

17. **Vendor::VendorsController**
    - Vendor profile management (create, edit, update)

18. **Vendor::VendorEventsController**
    - Create vendor presence at events
    - QR code display for booth scanner
    - Broadcast action (send SMS to booth visitors)

---

## Background Jobs & Async Processing

### Job Infrastructure
- **Queue System**: Sidekiq with Redis
- **Queue Configuration**: Named queues (e.g., `:broadcasts`)
- **Retry Strategy**: Exponential backoff with configurable attempts

### Jobs

1. **BroadcastSmsJob** (`/app/jobs/broadcast_sms_job.rb`)
   - **Purpose**: Send SMS broadcasts to visitors
   - **Queue**: `:broadcasts`
   - **Enqueue**: `BroadcastSmsJob.perform_later(broadcast_id)`
   - **Process**:
     1. Load broadcast with eager-loaded receipts
     2. Iterate through pending broadcast_receipts
     3. For each: Check phone exists, call TwilioSmsService
     4. Update receipt status (delivered/failed)
     5. Log results with counts
   - **Retry**: 3 attempts with polynomially longer delays
   - **Rate Limiting**: Sleep 0.05s per message to respect Twilio limits

2. **InvitationMailer** (Referenced but not yet implemented as job)
   - `deliver_later` queuing in place in `admin/events_controller.rb`
   - Enqueued from: `Admin::EventsController#bulk_invite`

---

## Service Objects & Utilities

### TwilioSmsService (`/app/services/twilio_sms_service.rb`)
**Purpose**: Single-responsibility wrapper for Twilio SMS API

**Architecture**:
- Class method: `send(to:, body:)` returns Result struct
- Never raises exceptions; returns status struct
- Credentials: Supports Rails credentials or ENV variables

**Result Struct**:
```ruby
Result = Struct.new(:success, :sid, :error) do
  def success?  # => true/false
  end
end
```

**Key Features**:
- `normalize_phone(phone)` - Convert to E.164 format (+1XXXXXXXXXX)
- Fallback: ENV vars when credentials not in Rails credentials
- Error logging with message context
- Handles Twilio errors gracefully

**Credentials Priority**:
1. `Rails.application.credentials.twilio[:account_sid|auth_token|phone_number]`
2. ENV['TWILIO_ACCOUNT_SID|TWILIO_AUTH_TOKEN|TWILIO_PHONE_NUMBER']

---

## Key Business Flows

### 1. Event Creation & Management Flow
```
Admin creates event → Event#create
├─ Validates: name, date, deadline, max_attendees
├─ Generates slug from name + year (auto-unique)
├─ Sets creator_id to current_user
├─ Associates: venue, categories
└─ Creates public_url via slug
```

**Visibility Options**:
- `public_rsvp_enabled`: Allow public RSVPs via `/e/:slug`
- Event types determine features:
  - hosted: Full RSVP + check-in
  - participating: External link + show involvement
  - reference: Awareness only

---

### 2. RSVP Flow (Registered User)

**Authenticated User Path**:
```
User clicks "RSVP" → RsvpController#show
├─ Finds EventParticipant for user+event
├─ Displays RSVP form with custom questions
└─ Shows current status

User submits → RsvpController#update
├─ Validates status in ['yes', 'no', 'maybe', 'pending']
├─ Validates deadline not passed
├─ Creates or updates EventParticipant
├─ Stores custom RSVP answers as JSON
├─ Sends EventNotificationMailer#rsvp_notification (async)
└─ Redirects with confirmation
```

**Public RSVP Path** (if `public_rsvp_enabled`):
```
Guest visits /e/:slug → PublicEventsController#show
├─ Shows event details
└─ Displays RSVP form

Guest or logged-in user submits → PublicEventsController#rsvp
├─ For logged-in user:
│  └─ Check existing RSVP, update or create
├─ For guest:
│  └─ Create EventParticipant with guest fields
├─ Stores rsvp_status and custom answers
└─ Redirects to confirmation page with participant_id
```

**RSVP Data Structure**:
- `rsvp_status`: 'yes', 'no', 'maybe', 'pending'
- `rsvp_answers`: JSON hash of custom form responses
- `invited_at`: When invitation was sent
- `responded_at`: When they responded

---

### 3. Guest RSVP Flow
```
PublicEventsController#rsvp receives form
├─ is_guest = true
├─ guest_name, guest_email, guest_phone populated
├─ user_id = nil
├─ Validates: guest_name present, phone or email present
└─ EventParticipant.display_name returns guest_name
```

---

### 4. Check-in Flow

**QR Code Path**:
```
Participant receives QR code via email/PDF
├─ QR links to: /checkin/verify?token=X&event=Y&participant=Z
└─ QR code generated on EventParticipant#after_create

Participant scans → CheckinController#verify
├─ Validates token against event + participant ID
├─ Checks not already checked in
└─ Returns status page: 'ready' or 'already_checked_in'

Participant taps confirm → CheckinController#process
├─ Validates token+event+participant combo
├─ Calls EventParticipant#check_in!(method: :qr_code)
├─ Sets: checked_in_at (timestamp), check_in_method, checked_in_by
└─ Redirects to success page
```

**Manual Check-in** (Staff):
```
Admin staff → /admin/checkin/dashboard/:event_id
├─ Lists participants by RSVP status
├─ Search/filter interface
├─ Bulk check-in operations
└─ Marks participants manually with check_in_method: :manual
```

**Undo Check-in**:
- `EventParticipant#undo_checkin!` clears checked_in_at, method, checked_in_by

---

### 5. Vendor Booth & Visitor Opt-in Flow

**Vendor Setup**:
```
Vendor access /vendor → Vendor::Dashboard
├─ Lists vendors they own or have access to
└─ Click vendor → Vendor::VendorsController#show

Vendor creates VendorEvent for an event
├─ Selects category: dealer, artist_alley, sponsor, exhibitor, panelist
├─ System generates unique QR token
├─ QR links to: /join/:qr_token
└─ Vendor can print/display QR code at booth
```

**Visitor Opt-in Path**:
```
Visitor scans QR at booth → VisitorOptInsController#show
├─ Shows opt-in form with vendor name + category copy
├─ e.g., "Follow Artist Name for art updates"
└─ Requests: name, phone or email

Visitor submits → VisitorOptInsController#create
├─ Creates ConOptIn record:
│  ├─ Linked to: event, vendor_event (first vendor)
│  ├─ Stores: name, phone, email
│  └─ Sets: opted_in_at timestamp
├─ Creates VendorOptIn (tracks this opt-in across vendors if they scan more)
└─ Redirects to welcome page → event feed

Visitor browses event feed → /feed/:event_slug
├─ Shows event info, vendor list, announcements
└─ ConOptIn becomes target for future broadcasts
```

---

### 6. SMS Broadcast Flow

**Vendor Creates Broadcast**:
```
Vendor navigates to VendorEvent#broadcast (admin interface)
├─ Creates Broadcast record:
│  ├─ channel: :sms
│  ├─ scope: :booth_visitors or :entire_con
│  ├─ message: (max 160 chars)
│  └─ vendor_event_id
└─ System creates BroadcastReceipt for each recipient
   ├─ If scope = booth_visitors: con_opt_ins for this vendor
   └─ If scope = entire_con: all con_opt_ins for the event
```

**Send Broadcast**:
```
Admin triggers send → BroadcastSmsJob.perform_later(broadcast_id)

Sidekiq processes:
├─ Loads Broadcast with eager-loaded receipts
├─ Iterates pending BroadcastReceipt records:
│  ├─ Calls TwilioSmsService.send(to: phone, body: message)
│  ├─ Updates receipt: status, delivered_at, sid
│  └─ Logs success/failure per recipient
├─ Sleep 0.05s between sends (rate limiting)
└─ Logs completion: "X sent, Y failed"
```

**Receipt Tracking**:
- BroadcastReceipt.status: pending → delivered (or failed)
- Stores Twilio message SID for delivery verification
- Admin can see delivery report per broadcast

---

### 7. Event Admin Workflow: Bulk Invite

```
Admin views Event#show
├─ Participant counts by RSVP status
├─ Can click "Add Participant" to manually invite
└─ Can bulk-select users to invite

Admin selects users + clicks "Bulk Invite"
→ Admin::EventsController#bulk_invite

Process:
├─ Validates: user_ids not empty
├─ For each user_id:
│  ├─ Find or initialize EventParticipant
│  ├─ Set: role = 'attendee', rsvp_status = 'pending', invited_at
│  ├─ Save record
│  ├─ Enqueue: InvitationMailer.event_invitation(participant).deliver_later
│  └─ Increment success_count
└─ Redirect with "Successfully invited N users"
```

---

## Authentication & Authorization

### Devise Configuration
**Model**: User
- Modules: :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
- Routes: Generated by `devise_for :users`
- Mailers: Devise::Mailer (included)

### Role-Based Access Control (RBAC)

**Role Hierarchy** (not enforced in code, but conceptually):
```
super_admin (full access)
├─ event_admin (can manage events)
├─ venue_admin (can manage venues)
└─ vendor_admin (can manage vendors)
attendee (no admin access)
```

**Permission Methods** on User:
```ruby
super_admin?        # role == 'super_admin'
admin?              # !attendee?
can_manage_events?  # super_admin? || event_admin?
can_manage_venues?  # super_admin? || venue_admin?
can_manage_vendors? # super_admin? || vendor_admin?
```

### Controller-Level Authorization

**Admin Namespace**:
- `before_action :ensure_admin!` in Admin::BaseController
  - Redirects non-admins to root_path
  - Specific actions use `before_action :ensure_can_manage_events!` etc.

**Vendor Namespace**:
- `before_action :find_vendor` + `vendor.accessible_by?(current_user)?`
  - Vendor is accessible if:
    - current_user == vendor.user (owner), OR
    - current_user in vendor.vendor_users (shared access)

**Public Controllers**:
- `skip_before_action :authenticate_user!` for public routes
- Some actions check `current_user` if logged in, work as guest otherwise

---

## Data Structure Highlights

### JSON Serialization
1. **Event#custom_questions** - Array of custom RSVP questions
   ```ruby
   [{question: "Dietary restrictions?", required: true}, ...]
   ```

2. **EventParticipant#rsvp_answers** - Hash of custom answers
   ```ruby
   {"dietary_restrictions" => "Vegetarian", "guest_count" => "2"}
   ```

3. **VendorEvent#metadata** - Flexible vendor event data
   ```ruby
   {"booth_number" => "A-12", "hall" => "Main Hall"}
   ```

### QR Code Tokens
- **EventParticipant#qr_code_token** - Unique check-in token
- **VendorEvent#qr_token** - Unique booth scanner token
- Both generated via SecureRandom.urlsafe_base64(16)
- Full QR URLs built with APP_HOST env var

---

## Key Dependencies & Libraries

| Gem | Purpose |
|-----|---------|
| rails 7.1 | Web framework |
| devise | Authentication |
| pg | PostgreSQL driver |
| sidekiq | Background job processing |
| redis | Sidekiq backend + caching |
| twilio-ruby | SMS API |
| kaminari | Pagination |
| bootstrap 5 | UI framework |
| simple_form | Form builder |
| icalendar | Calendar export (.ics) |
| sprockets-rails | Asset pipeline |
| turbo-rails | Turbo Drive/Frames |
| stimulus-rails | JS framework |
| image_processing | Active Storage image processing |

**Dev/Test**:
- rspec-rails, factory_bot_rails, shoulda-matchers
- capybara, selenium-webdriver
- database_cleaner, faker

---

## Important Patterns & Conventions

### Model Inclusions
- `HasExternalId` - Adds external_id field for API integrations (used in User, Event, Category, Vendor)

### Slug Generation
- Auto-generated on Event and Category create
- Format: event name parameterized + year (e.g., "spring-conference-2024")
- Uniqueness: Appends counter if collision (spring-conference-2024-2)
- Used for public URLs: `/e/:slug`

### Eager Loading
- EventsController#index: `.includes(:venue, :creator, event_participants: :user)`
- BroadcastSmsJob: `.includes(broadcast_receipts: :con_opt_in)`
- Prevents N+1 queries

### Scopes
- Event: `upcoming`, `past`, `public_rsvp`
- EventParticipant: `vendors`, `attendees`, `organizers`, `confirmed`, `checked_in`, `guests`, `registered_users`
- User: `admins`, `super_admins`, `attendees_only`, `text_capable`, `registered`, `with_phone`
- Broadcast: `sent`, `pending`, `recent`
- BroadcastReceipt: `failed`, `delivered`

### Strong Parameters
- Whitelist custom question arrays and category_id arrays
- Reject blank values from arrays before passing to model

---

## Common Queries & Operations

```ruby
# Find event by slug (common in controllers)
Event.find_by(slug: params[:id])

# Find participant for user
user.participant_for_event(event)  # Uses cache

# Get RSVP status for user at event
user.rsvp_status_for_event(event)

# Count confirmed attendees
event.attendees_count  # yes/1 responses only

# Check if spot available
event.spots_remaining > 0

# Generate check-in QR link
participant.qr_code_data

# Send SMS via service
TwilioSmsService.send(to: '+15035551234', body: 'Hello!')

# Get attendee list by role
event.event_participants.organizers
event.event_participants.vendors
event.event_participants.attendees
```

---

## Testing Notes

Test frameworks: RSpec, Factory Bot, Shoulda Matchers, Capybara, Selenium

Key areas to test:
- RSVP status transitions and deadline validation
- Permission checks (admin roles, vendor access)
- Guest RSVP vs. registered user RSVP
- Check-in QR token generation and verification
- Bulk invite email enqueuing
- Broadcast SMS job with rate limiting
- Vendor opt-in flow and ConOptIn creation

---

## Deployment Considerations

1. **Background Jobs**: Start Sidekiq process with named queues (`:broadcasts`)
2. **Redis**: Required for Sidekiq and session storage
3. **Credentials**: Set Twilio keys in Rails credentials or ENV vars
4. **APP_HOST**: Set for correct QR code URLs (e.g., `example.com` or `localhost:3000`)
5. **Email**: Configure ActionMailer for invitations and RSVP confirmations
6. **Database**: PostgreSQL (pg gem)
7. **Static Files**: Serve via Sprockets (CSS/JS with asset pipeline)

---

## Important Architectural Notes

### Event Form Category Management
The event form includes a critical hidden field for category management:
```erb
<%= form.hidden_field :category_ids, value: '', multiple: true %>
```
This hidden empty field ensures that unchecking all categories correctly clears them on save. Without it, Rails would not recognize that categories should be removed.

### RSVP Data Model History
**IMPORTANT**: This system went through a major refactoring documented in `INDEX.md`, `QUICK_REFERENCE.md`, and `PHASE1_CHECKLIST.md`. The key change:
- **OLD (incorrect)**: User model had `rsvp_status` enum - one global status per user
- **NEW (correct)**: EventParticipant has `rsvp_status` - per-event status

**Never reference `user.rsvp_status`** - always use `participant.rsvp_status` or `user.rsvp_status_for_event(event)`.

### Guest vs Registered User Patterns
Throughout the codebase, use these patterns for handling both guest and registered participants:
```ruby
# Get display information (works for both)
participant.display_name    # Returns guest_name or user.full_name
participant.display_email   # Returns guest_email or user.email
participant.display_phone   # Returns guest_phone or user.phone

# Check if guest
participant.is_guest?       # Boolean field
participant.user_id.nil?    # Also works

# Validation
validates :guest_name, presence: true, if: -> { is_guest? }
validates :user, presence: true, unless: -> { is_guest? }
```

### Background Job Strategy
- **Email invitations**: Use `.deliver_later(queue: :mailers)` not `.deliver_now`
- **SMS broadcasts**: Use `BroadcastSmsJob.perform_later(broadcast_id)`
- **Rate limiting**: SMS job includes 0.05s sleep between messages for Twilio compliance
- **Retry logic**: Jobs have exponential backoff configured in Sidekiq

### Security Tokens
Two types of QR tokens are used:
1. **EventParticipant#qr_code_token** - For check-in at event entrance
   - Generated: `after_create` callback
   - URL: `/checkin/verify?token=X&event=Y&participant=Z`
   - Validation: Must match event_id + participant_id + token

2. **VendorEvent#qr_token** - For visitor opt-in at vendor booth
   - Generated: `after_create` callback
   - URL: `/join/:qr_token`
   - Single token identifies vendor + event

### N+1 Query Prevention
Always eager load associations in index actions:
```ruby
# Good
Event.includes(:venue, :creator, event_participants: :user)

# Bad (causes N+1)
Event.all
```

Key locations with eager loading:
- `Admin::EventsController#index`
- `BroadcastSmsJob#perform`
- Any list view with associations

### Permission Checking Patterns
```ruby
# In controllers
before_action :ensure_super_admin!           # Super admin only
before_action :ensure_can_manage_events!     # Super or event admin
before_action :authenticate_user!            # Any logged-in user

# In views
<% if current_user&.can_manage_events? %>
  # Show admin controls
<% end %>

# For vendors
def find_vendor
  @vendor = Vendor.find(params[:id])
  redirect_to root_path unless @vendor.accessible_by?(current_user)
end
```

### Environment Variables
Required for production:
- `APP_HOST` - Domain for QR code generation (e.g., "example.com")
- `TWILIO_ACCOUNT_SID` - Twilio account identifier
- `TWILIO_AUTH_TOKEN` - Twilio authentication token
- `TWILIO_PHONE_NUMBER` - Sending phone number (E.164 format: +1XXXXXXXXXX)
- `REDIS_URL` - Redis connection string (for Sidekiq)
- `DATABASE_URL` - PostgreSQL connection string

Optional (fall back to Rails credentials):
- Use `rails credentials:edit` to set `twilio:` keys as alternative to ENV vars

---

## Project Documentation Reference

Key documentation files in the repository:
- `docs/TAXONOMY.md` - Complete taxonomy system reference (5 facets, hierarchy, examples)
- `FEATURE_CHECKLIST.md` - Feature implementation checklist and sprint backlog
- `QUICK_REFERENCE.md` - Phase 1 refactoring quick reference (RSVP data model fix)
- `INDEX.md` - Phase 1 implementation package overview
- `TESTING_GUIDE.md` - RSpec test suite documentation
- `SIDEKIQ_SETUP.md` - Background job configuration
- `START_SERVICES.md` - How to run Rails + Sidekiq together
- `PRE_PUSH_VALIDATION.md` - Pre-push validation script documentation

---

## Future Enhancements (From Code Comments)

- Multi-day event scheduling (see `FEATURE_CHECKLIST.md` for design notes)
- Venue modal on event form for quick-add (backlog item)
- URL-based category filtering on public events index (`/events?tag=windchill`)
- Parent/child category rollup in filtering (TBD)
- Additional broadcast channels (email, feed beyond SMS)
- Mobile app API endpoints (skeleton exists in `/api/v1`)
- User interest self-selection from taxonomy (Phase 3)
- AI-assisted interest inference (Phase 4)
- More sophisticated reporting/analytics

