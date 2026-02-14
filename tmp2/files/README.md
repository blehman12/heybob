# Confab - Event Management System

A modern Ruby on Rails application for managing boutique events with RSVP tracking, QR code check-in, and participant management.

## 📋 Overview

Confab makes it easy to:
- Create and manage events
- Send invitations and track RSVPs
- Check in attendees with QR codes
- Manage participants (attendees, vendors, organizers)
- Track event capacity and responses
- Export participant lists

**Perfect for:** Small to medium events (parties, conferences, meetups, trade shows)

## 🚀 Features

### Event Management
- ✅ Create events with venue, date, capacity
- ✅ Custom RSVP questions
- ✅ RSVP deadline tracking
- ✅ Capacity management with spot tracking
- ✅ Event calendar export (.ics)

### Participant Management
- ✅ Role-based participants (Attendee, Vendor, Organizer)
- ✅ Bulk user import/export (CSV)
- ✅ Email invitations
- ✅ RSVP status tracking (Yes, No, Maybe, Pending)
- ✅ Check-in tracking

### Check-in System
- ✅ QR code generation per participant
- ✅ Mobile-friendly QR scanner
- ✅ Manual check-in option
- ✅ Bulk check-in
- ✅ Real-time check-in dashboard

### Admin Features
- ✅ Dashboard with event overview
- ✅ User management
- ✅ Venue management
- ✅ CSV exports for reporting
- ✅ Background job monitoring (Sidekiq)

## 🛠 Tech Stack

- **Ruby:** 3.3.3
- **Rails:** 7.1.5
- **Database:** PostgreSQL (production), SQLite3 (dev/test)
- **Background Jobs:** Sidekiq + Redis
- **Frontend:** Turbo, Stimulus, Bootstrap 5
- **Authentication:** Devise
- **Testing:** RSpec, FactoryBot, Capybara

## 📦 Installation

### Prerequisites

- Ruby 3.3.3 (use rbenv or rvm)
- PostgreSQL 12+ (for production)
- Redis 6+ (for Sidekiq)
- Node.js 18+ (for asset compilation)

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/confab.git
   cd confab
   ```

2. **Install Ruby dependencies**
   ```bash
   bundle install
   ```

3. **Setup database**
   ```bash
   # Development uses SQLite by default
   rails db:create
   rails db:migrate
   rails db:seed  # Creates sample data
   ```

4. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your settings:
   # - REDIS_URL=redis://localhost:6379/1
   # - MAILER_FROM_EMAIL=your-email@example.com
   ```

5. **Start Redis** (in separate terminal)
   ```bash
   redis-server
   ```

6. **Start Sidekiq** (in separate terminal)
   ```bash
   bundle exec sidekiq -C config/sidekiq.yml
   ```

7. **Start Rails server**
   ```bash
   rails server
   ```

8. **Visit the app**
   ```
   http://localhost:3000
   ```

### Using Foreman (Alternative)

Start all services at once:
```bash
gem install foreman
foreman start -f Procfile.dev
```

## 👤 Creating Your First Admin User

```bash
rails console

# Create admin user
User.create!(
  email: 'admin@example.com',
  password: 'password',  # Change this!
  password_confirmation: 'password',
  first_name: 'Admin',
  last_name: 'User',
  phone: '555-1234',
  company: 'Your Company',
  role: :admin
)
```

Then login at: `http://localhost:3000/users/sign_in`

## 🧪 Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/event_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

## 📧 Email Configuration

### Development (Letter Opener)
Emails open in browser automatically. No configuration needed.

### Production (SendGrid, Mailgun, etc.)
```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: ENV['SMTP_ADDRESS'],
  port: ENV['SMTP_PORT'],
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: 'plain',
  enable_starttls_auto: true
}
```

Set environment variables:
```bash
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-api-key
MAILER_FROM_EMAIL=events@yourdomain.com
```

## 🚢 Deployment

### Render.com (Recommended)

1. **Create render.yaml** (already included)
2. **Connect GitHub repo** to Render
3. **Set environment variables:**
   - `DATABASE_URL` (auto-configured)
   - `REDIS_URL` (auto-configured)
   - `RAILS_MASTER_KEY` (from config/master.key)
   - `SMTP_*` settings for email

4. **Deploy**
   - Web service: `bundle exec puma -C config/puma.rb`
   - Worker service: `bundle exec sidekiq -C config/sidekiq.yml`

### Heroku

```bash
# Create app
heroku create confab-yourname

# Add Redis
heroku addons:create heroku-redis:mini

# Add PostgreSQL (free)
heroku addons:create heroku-postgresql:essential-0

# Set config
heroku config:set RAILS_MASTER_KEY=your-master-key

# Deploy
git push heroku main

# Migrate
heroku run rails db:migrate

# Create admin
heroku run rails console
```

### Docker

```bash
# Build
docker build -t confab .

# Run
docker-compose up
```

## 📁 Project Structure

```
app/
├── controllers/
│   ├── admin/           # Admin dashboard, users, events, venues
│   ├── checkin/         # QR code check-in
│   ├── rsvp/            # RSVP management
│   └── dashboard/       # User dashboard
├── models/
│   ├── event.rb
│   ├── event_participant.rb
│   ├── user.rb
│   └── venue.rb
├── mailers/
│   ├── invitation_mailer.rb
│   └── event_notification_mailer.rb
├── views/
│   ├── admin/
│   ├── checkin/
│   ├── dashboard/
│   └── rsvp/
└── jobs/
    └── (Sidekiq background jobs)

config/
├── database.yml         # Database configuration
├── routes.rb            # URL routing
└── sidekiq.yml          # Background job configuration

spec/
├── models/              # Model tests
├── controllers/         # Controller tests
├── features/            # Integration tests
└── system/              # End-to-end tests
```

## 🔧 Common Tasks

### Create an Event
```ruby
venue = Venue.create!(name: "Portland Convention Center", address: "777 NE MLK Jr Blvd")

event = Event.create!(
  name: "Cinco de Mayo Party",
  description: "Annual celebration with food and music",
  venue: venue,
  creator: User.admin.first,
  event_date: 1.month.from_now,
  start_time: "18:00",
  end_time: "23:00",
  max_attendees: 100,
  rsvp_deadline: 2.weeks.from_now
)
```

### Invite Users to Event
```ruby
users = User.where(role: :attendee).limit(50)
users.each do |user|
  participant = event.event_participants.create!(
    user: user,
    role: :attendee,
    rsvp_status: :pending,
    invited_at: Time.current
  )
  
  InvitationMailer.event_invitation(participant).deliver_later
end
```

### Export Participants
Visit: `/admin/events/:id/export_participants.csv`

Or programmatically:
```ruby
require 'csv'

CSV.open("participants.csv", "w") do |csv|
  csv << ["Name", "Email", "RSVP", "Checked In"]
  
  event.event_participants.includes(:user).each do |p|
    csv << [p.user.full_name, p.user.email, p.rsvp_status, p.checked_in?]
  end
end
```

## 🐛 Troubleshooting

### Redis connection errors
```bash
# Check if Redis is running
redis-cli ping
# Should return: PONG

# Start Redis
# Mac:
brew services start redis
# Linux:
sudo systemctl start redis
```

### Database migration issues
```bash
# Reset database (development only!)
rails db:drop db:create db:migrate db:seed

# Or just run migrations
rails db:migrate
```

### Email not sending
```bash
# Check Sidekiq is running
ps aux | grep sidekiq

# Check Sidekiq web UI
open http://localhost:3000/admin/sidekiq

# View Sidekiq logs
tail -f log/sidekiq.log
```

### Tests failing
```bash
# Ensure test database is up to date
RAILS_ENV=test rails db:migrate

# Clear test cache
rails tmp:clear
```

## 📊 Monitoring

### Sidekiq Web UI
Visit `/admin/sidekiq` (requires admin login)

### Performance Monitoring
Consider adding:
- **New Relic** - Application performance
- **Skylight** - Rails-specific monitoring
- **Sentry** - Error tracking

## 🤝 Contributing

This is a personal project, but suggestions welcome!

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

This project is private/proprietary. Contact owner for licensing.

## 🙏 Acknowledgments

- Built with Ruby on Rails
- Uses Bootstrap for UI
- QR code generation via rqrcode gem
- Background jobs via Sidekiq

## 📞 Support

For questions or issues:
- Open a GitHub issue
- Email: bob@nwtechgroup.com

## 🗺 Roadmap

### Upcoming Events (Proof of Concept)
- [ ] Cinco de Mayo Party
- [ ] Windchill Spring Event
- [ ] Sakurako Anima Event
- [ ] Poe Show Follow-up

### Future Features
- [ ] SMS notifications (Twilio integration)
- [ ] Payment processing for paid events
- [ ] Mobile app (React Native)
- [ ] Multi-language support
- [ ] Analytics dashboard
- [ ] White-label branding
- [ ] API for third-party integrations

---

**Current Version:** 1.0.0  
**Last Updated:** February 2026  
**Maintainer:** Bob Lehmann - Northwest Technology Group
