# ── Production-safe seeds (run in ALL environments) ───────────────────────────

# Twilio toll-free verification: seed a known QR token for the opt-in URL
TWILIO_QR_TOKEN = "SAKURACON2026"
unless VendorEvent.exists?(qr_token: TWILIO_QR_TOKEN)
  puts "Seeding Twilio verification VendorEvent (#{TWILIO_QR_TOKEN})..."
  owner = User.find_by(email: "blehman12@comcast.net") || User.where(role: 1).first || User.first
  if owner
    event = Event.find_by(slug: "sakuracon-2026") ||
            Event.where("name ILIKE ?", "%sakura%").first ||
            Event.create!(
              name: "SakuraCon 2026", slug: "sakuracon-2026",
              event_date: DateTime.new(2026, 3, 27, 10, 0, 0),
              lifecycle_status: 1, creator_id: owner.id
            )
    vendor = Vendor.find_or_create_by!(name: "Portland KPOP CO", user: owner) do |v|
      v.participant_type = :business
      v.description = "Portland's premier KPOP merchandise vendor"
    end
    ve = VendorEvent.new(vendor: vendor, event: event, category: :dealer,
                         qr_token: TWILIO_QR_TOKEN,
                         metadata: { "booth_number" => "247", "hall" => "Main Hall" }.to_json)
    ve.save!
    puts "  ✅ Created /join/#{TWILIO_QR_TOKEN}"
  else
    puts "  ⚠ No user found — skipping Twilio verification seed."
  end
else
  puts "  Twilio verification seed already present (/join/#{TWILIO_QR_TOKEN})"
end

# ── Production guard — everything below is dev/test only ──────────────────────
if Rails.env.production?
  puts "SKIPPING destructive wipe — production environment."
  puts "Run individual seed files with: rails runner db/seeds/<file>.rb"
  return
end

# Clear existing data (dev/test only)
puts "Clearing existing data..."
Categorization.destroy_all
Category.destroy_all
EventParticipant.destroy_all
Event.destroy_all
Venue.destroy_all
User.destroy_all

puts "Creating admin users..."
admin = User.create!(
  first_name: 'Admin',
  last_name: 'User',
  email: 'admin@nwtg.com',
  password: 'password123',
  phone: '503-555-0100',
  company: 'NWTG',
  role: 1
)

# Create sample venues
puts "Creating venues..."
venues = []

venues << Venue.create!(
  name: 'Portland Tech Center',
  address: '9205 SW Gemini Dr, Beaverton, OR 97008',
  description: 'Modern conference facility with state-of-the-art AV equipment',
  capacity: 150
)

venues << Venue.create!(
  name: 'Pearl District Conference Room',
  address: '1120 NW Couch St, Portland, OR 97209',
  description: 'Intimate meeting space in the heart of Portland',
  capacity: 40
)

venues << Venue.create!(
  name: 'OHSU Collaborative Life Sciences Building',
  address: '2730 SW Moody Ave, Portland, OR 97201',
  description: 'University venue with flexible meeting spaces',
  capacity: 80
)

# Create events
puts "Creating events..."
events = []

# Current upcoming event
current_event = Event.create!(
  name: 'PTC Windchill Community Meetup - Fall 2024',
  description: 'Join fellow PTC Windchill users for networking, best practices sharing, and product updates. Features presentations from PTC engineers and customer success stories.',
  event_date: 3.weeks.from_now.change(hour: 18),
  start_time: Time.parse('6:00 PM'),
  end_time: Time.parse('9:00 PM'),
  max_attendees: 60,
  rsvp_deadline: 2.weeks.from_now,
  venue: venues[0],
  creator: admin
)
events << current_event

# Future event
winter_event = Event.create!(
  name: 'PTC Windchill Advanced Training Workshop',
  description: 'Deep-dive technical session covering advanced Windchill configuration and customization techniques.',
  event_date: 8.weeks.from_now.change(hour: 9),
  start_time: Time.parse('9:00 AM'),
  end_time: Time.parse('4:00 PM'),
  max_attendees: 25,
  rsvp_deadline: 6.weeks.from_now,
  venue: venues[1],
  creator: admin
)
events << winter_event

# Past event for demo purposes
past_event = Event.create!(
  name: 'PTC Windchill Summer Networking Event',
  description: 'Successful networking event from summer 2024.',
  event_date: 2.months.ago.change(hour: 18),
  start_time: Time.parse('6:00 PM'),
  end_time: Time.parse('8:30 PM'),
  max_attendees: 45,
  rsvp_deadline: 10.weeks.ago,
  venue: venues[2],
  creator: admin
)
events << past_event

# Create realistic users with company diversity
puts "Creating users..."
companies = [
  'Boeing', 'Intel', 'Nike', 'Precision Castparts', 'Daimler Trucks',
  'Adidas', 'Mentor Graphics', 'Lattice Semiconductor', 'Xerox',
  'Freightliner', 'Columbia Sportswear', 'Leupold & Stevens'
]

# Create organizers
organizers = []
3.times do |i|
  organizer = User.create!(
    first_name: ['Sarah', 'Michael', 'Jennifer'][i],
    last_name: ['Johnson', 'Chen', 'Rodriguez'][i],
    email: "organizer#{i+1}@nwtg.com",
    password: 'password123',
    phone: "503-555-02#{10+i}",
    company: 'NWTG',
    text_capable: true
  )
  organizers << organizer
  
  # Add as organizer to current event
  EventParticipant.create!(
    event: current_event,
    user: organizer,
    role: 'organizer',
    rsvp_status: 'yes',
    invited_at: 3.weeks.ago,
    responded_at: 2.weeks.ago
  )
end

# Create vendors
vendors = []
4.times do |i|
  vendor = User.create!(
    first_name: ['David', 'Lisa', 'Mark', 'Amanda'][i],
    last_name: ['Wilson', 'Thompson', 'Davis', 'Miller'][i],
    email: "vendor#{i+1}@#{['coretech', 'solutions', 'consulting', 'systems'][i]}.com",
    password: 'password123',
    phone: "503-555-03#{10+i}",
    company: ['CoreTech Solutions', 'Enterprise Solutions Inc', 'PLM Consulting Group', 'Tech Systems LLC'][i],
    text_capable: [true, false, true, true][i]
  )
  vendors << vendor
  
  # Add as vendor to current event
  EventParticipant.create!(
    event: current_event,
    user: vendor,
    role: 'vendor',
    rsvp_status: ['yes', 'yes', 'maybe', 'yes'][i],
    invited_at: 3.weeks.ago,
    responded_at: rand(2.weeks.ago..1.day.ago)
  )
end

# Create regular attendees
20.times do |i|
  first_names = ['Alex', 'Taylor', 'Jordan', 'Casey', 'Morgan', 'Jamie', 'Riley', 'Avery', 'Quinn', 'Blake',
                 'Drew', 'Cameron', 'Sage', 'River', 'Phoenix', 'Skyler', 'Rowan', 'Emery', 'Finley', 'Hayden']
  last_names = ['Smith', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez',
                'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez']
  
  user_rsvp_status = ['pending', 'yes', 'maybe', 'no'].sample
  
  user = User.create!(
    first_name: first_names[i],
    last_name: last_names[i],
    email: "user#{i+1}@#{companies.sample.downcase.gsub(' ', '')}.com",
    password: 'password123',
    phone: "503-555-#{sprintf('%04d', 4000 + i)}",
    company: companies.sample,
    text_capable: [true, false].sample
  )
  
  # Add some to current event
  if rand < 0.7  # 70% chance
    rsvp_status = user_rsvp_status
    responded_at = rsvp_status == 'pending' ? nil : rand(2.weeks.ago..1.day.ago)
    
    EventParticipant.create!(
      event: current_event,
      user: user,
      role: 'attendee',
      rsvp_status: rsvp_status,
      invited_at: rand(4.weeks.ago..1.week.ago),
      responded_at: responded_at
    )
  end
  
  # Add some to winter event
  if rand < 0.3  # 30% chance
    EventParticipant.create!(
      event: winter_event,
      user: user,
      role: 'attendee',
      rsvp_status: 'pending'
    )
  end
  
  # Add to past event
  if rand < 0.4  # 40% chance
    EventParticipant.create!(
      event: past_event,
      user: user,
      role: 'attendee',
      rsvp_status: ['yes', 'no'].sample,
      responded_at: rand(12.weeks.ago..8.weeks.ago)
    )
  end
end

# Add some more participants to winter event from existing users
User.limit(10).each do |user|
  next if user.event_participants.where(event: winter_event).exists?
  
  if rand < 0.4
    EventParticipant.create!(
      event: winter_event,
      user: user,
      role: 'attendee',
      rsvp_status: 'pending'
    )
  end
end

puts "\n" + "="*60
puts "DATABASE SEEDING COMPLETED!"
puts "="*60
puts "Login Credentials:"
puts "  Admin: admin@nwtg.com / password123"
puts "  Test Users: user1@boeing.com / password123 (and others)"
puts ""
puts "Statistics:"
puts "  Users: #{User.count}"
puts "  Venues: #{Venue.count}"
puts "  Events: #{Event.count}"
puts "  Event Participants: #{EventParticipant.count}"
puts "  Confirmed RSVPs: #{EventParticipant.where(rsvp_status: 'yes').count}"
puts "  Vendors: #{EventParticipant.where(role: 'vendor').count}"
puts "  Organizers: #{EventParticipant.where(role: 'organizer').count}"
puts ""
puts "Current Event Participants:"
current_participants = EventParticipant.where(event: current_event)
puts "  Total: #{current_participants.count}"
puts "  Confirmed: #{current_participants.where(rsvp_status: 'yes').count}"
puts "  Maybe: #{current_participants.where(rsvp_status: 'maybe').count}"
puts "  Declined: #{current_participants.where(rsvp_status: 'no').count}"
puts "  Pending: #{current_participants.where(rsvp_status: 'pending').count}"
puts ""
puts "Ready to test at: http://localhost:3000"
puts "Admin panel at: http://localhost:3000/admin"

# ── Taxonomy ──────────────────────────────────────────────────────────────────
load Rails.root.join('db/seeds/categories.rb')
load Rails.root.join('db/seeds/categorizations.rb')

# ── Vendors ───────────────────────────────────────────────────────────────────
load Rails.root.join('db/seeds/vendors.rb')

# ── Smoke test account ────────────────────────────────────────────────────────
smoketest = User.find_or_create_by!(email: 'smoketest@heybob.app') do |u|
  u.first_name = 'Smoke'
  u.last_name  = 'Test'
  u.password   = 'Sm0keTest!'
  u.phone      = '503-555-9999'
  u.company    = 'HeyBob QA'
  u.role       = :super_admin
end
puts "Smoke test account: #{smoketest.email} (#{smoketest.persisted? ? 'ready' : 'ERROR'})"
