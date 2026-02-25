# db/seeds/vendors.rb
# Creates sample vendor records and links them to existing events.
# Safe to re-run — uses find_or_create_by on name+user.

puts "Seeding vendors..."

meetup  = Event.find_by(slug: 'ptc-windchill-community-meetup-fall-2024-2026')
summer  = Event.find_by(slug: 'ptc-windchill-summer-networking-event-2025')
training = Event.find_by(slug: 'ptc-windchill-advanced-training-workshop-2026')

vendors_data = [
  {
    owner_email:      'vendor1@coretech.com',
    name:             'CoreTech Solutions',
    participant_type: :business,
    description:      'PLM implementation and integration specialists. We help manufacturing companies deploy and optimize Windchill environments.',
    hook_line:        'Your Windchill integration experts',
    website:          'https://coretechsolutions.example.com',
    instagram_handle: 'coretechsolutions',
    events: [
      { event: meetup,  category: :sponsor,   booth_number: 'S-01', hall: 'Main Hall' },
      { event: summer,  category: :exhibitor, booth_number: 'E-03', hall: 'Main Hall' },
    ]
  },
  {
    owner_email:      'vendor2@solutions.com',
    name:             'Enterprise Solutions Inc',
    participant_type: :business,
    description:      'End-to-end PLM consulting from requirements through go-live. Specializing in Windchill, Creo, and downstream MES integrations.',
    hook_line:        'PLM consulting from strategy to go-live',
    website:          'https://enterprisesolutions.example.com',
    twitter_handle:   'EntSolutionsInc',
    events: [
      { event: meetup,   category: :sponsor,   booth_number: 'S-02', hall: 'Main Hall' },
      { event: training, category: :panelist,  booth_number: nil,    hall: nil },
    ]
  },
  {
    owner_email:      'vendor3@consulting.com',
    name:             'PLM Consulting Group',
    participant_type: :business,
    description:      'Independent PLM consulting focused on process optimization and change management for engineering teams.',
    hook_line:        'People-first PLM transformation',
    website:          'https://plmconsultinggroup.example.com',
    events: [
      { event: meetup, category: :exhibitor, booth_number: 'E-05', hall: 'Main Hall' },
    ]
  },
  {
    owner_email:      'vendor4@systems.com',
    name:             'Tech Systems LLC',
    participant_type: :business,
    description:      'CAD/PLM hardware and workstation specialists. Certified Creo and Windchill performance tuning.',
    hook_line:        'The fastest Creo workstations in the room',
    website:          'https://techsystems.example.com',
    instagram_handle: 'techsystems_llc',
    tiktok_handle:    'techsystemsllc',
    events: [
      { event: meetup, category: :dealer, booth_number: 'D-12', hall: 'Exhibit Hall' },
    ]
  },
]

vendors_data.each do |vd|
  owner = User.find_by(email: vd[:owner_email])
  unless owner
    puts "  WARNING: user #{vd[:owner_email]} not found, skipping #{vd[:name]}"
    next
  end

  vendor = Vendor.find_or_create_by!(name: vd[:name], user: owner) do |v|
    v.participant_type  = vd[:participant_type]
    v.description       = vd[:description]
    v.hook_line         = vd[:hook_line]
    v.website           = vd[:website]
    v.instagram_handle  = vd[:instagram_handle]
    v.twitter_handle    = vd[:twitter_handle]
    v.tiktok_handle     = vd[:tiktok_handle]
  end

  vd[:events].each do |ev|
    next unless ev[:event]
    VendorEvent.find_or_create_by!(vendor: vendor, event: ev[:event]) do |ve|
      ve.category = ev[:category]
      ve.metadata = {
        'booth_number' => ev[:booth_number],
        'hall'         => ev[:hall]
      }.compact
    end
  end

  puts "  #{vendor.name} (#{vendor.participant_type}) — #{vd[:events].count} event(s)"
end

puts "Done. #{Vendor.count} vendors total."
