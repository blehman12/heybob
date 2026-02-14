# SIDEKIQ SETUP GUIDE
# Follow these steps to add background job processing to Confab

## Step 1: Add to Gemfile

Add these lines to your Gemfile:

```ruby
# Background job processing
gem 'sidekiq', '~> 7.2'

# Optional but recommended for monitoring
gem 'sidekiq-cron'  # For scheduled jobs (reminders, cleanup)
```

Then run:
```bash
bundle install
```

## Step 2: Configure Rails to use Sidekiq

# config/application.rb
Add this line inside the Application class:

```ruby
config.active_job.queue_adapter = :sidekiq
```

## Step 3: Create Sidekiq configuration file

# config/sidekiq.yml
Create this file with these contents:

```yaml
---
:concurrency: 5
:queues:
  - critical    # For time-sensitive jobs (check-in, etc)
  - mailers     # For all email jobs
  - default     # For everything else
  - low         # For cleanup, analytics, etc

:max_retries: 3

# Production settings
production:
  :concurrency: 10
  
# Development settings  
development:
  :concurrency: 2
```

## Step 4: Configure Redis connection

# config/initializers/sidekiq.rb
Create this file:

```ruby
# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { 
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
    network_timeout: 5
  }
end

Sidekiq.configure_client do |config|
  config.redis = { 
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
    network_timeout: 5
  }
end

# Optional: Configure job logging
Sidekiq.logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
```

## Step 5: Update routes for Sidekiq Web UI (Admin only)

# config/routes.rb
Add this inside the admin namespace:

```ruby
namespace :admin do
  # ... existing admin routes ...
  
  # Sidekiq Web UI (requires admin authentication)
  require 'sidekiq/web'
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
end
```

## Step 6: Create mailer jobs

Your existing mailers will automatically use Sidekiq when you call .deliver_later

# Example usage in controllers:
```ruby
# Old way (synchronous - blocks request):
InvitationMailer.event_invitation(participant).deliver_now

# New way (background - returns immediately):
InvitationMailer.event_invitation(participant).deliver_later(queue: :mailers)
```

## Step 7: Add Procfile for development

# Procfile.dev
Create this file in your project root:

```
web: bin/rails server -p 3000
worker: bundle exec sidekiq -C config/sidekiq.yml
```

Then you can run both with:
```bash
gem install foreman
foreman start -f Procfile.dev
```

Or run separately in two terminals:
```bash
# Terminal 1:
rails server

# Terminal 2:
bundle exec sidekiq -C config/sidekiq.yml
```

## Step 8: Production deployment (Render.com example)

# render.yaml
```yaml
services:
  - type: web
    name: confab-web
    env: ruby
    buildCommand: "bundle install && bundle exec rails assets:precompile && bundle exec rails db:migrate"
    startCommand: "bundle exec puma -C config/puma.rb"
    
  - type: worker
    name: confab-worker
    env: ruby
    buildCommand: "bundle install"
    startCommand: "bundle exec sidekiq -C config/sidekiq.yml"
    
databases:
  - name: confab-db
    databaseName: confab_production
    
  - name: confab-redis
    plan: starter  # Free tier includes Redis
```

## Step 9: Environment variables

Add to .env (development):
```
REDIS_URL=redis://localhost:6379/1
```

Add to production environment:
```
REDIS_URL=<your-production-redis-url>
```

## Step 10: Test it works

```bash
# Start Redis (if not running)
redis-server

# Start Sidekiq
bundle exec sidekiq -C config/sidekiq.yml

# In Rails console, test:
InvitationMailer.event_invitation(EventParticipant.first).deliver_later

# You should see the job appear in Sidekiq logs
# Check Sidekiq web UI at: http://localhost:3000/admin/sidekiq
```

## Monitoring in Production

Visit `/admin/sidekiq` to see:
- Active jobs
- Failed jobs (with retry)
- Queue sizes
- Processing speed

## Common Issues

**Redis connection error:**
```bash
# Make sure Redis is running:
redis-cli ping
# Should return: PONG

# If not installed:
# Mac:
brew install redis
brew services start redis

# Ubuntu:
sudo apt-get install redis-server
sudo systemctl start redis
```

**Jobs not processing:**
- Check Sidekiq is running: `ps aux | grep sidekiq`
- Check Redis is running: `redis-cli ping`
- Check logs: `tail -f log/sidekiq.log`

**Memory issues:**
- Reduce concurrency in sidekiq.yml
- Add worker memory limit in Procfile: 
  `worker: bundle exec sidekiq -C config/sidekiq.yml -m 512`
