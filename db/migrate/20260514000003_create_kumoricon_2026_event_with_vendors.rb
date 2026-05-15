class CreateKumoricon2026EventWithVendors < ActiveRecord::Migration[7.1]
  def up
    return unless Rails.env.development? || Rails.env.production?

    admin = User.find_by(email: 'admin@nwtg.com')
    unless admin
      puts "Admin user not found — skipping Kumoricon 2026 setup"
      return
    end

    # Find or create venue
    venue = Venue.find_or_create_by!(name: 'Oregon Convention Center') do |v|
      v.address  = '777 NE Martin Luther King Jr Blvd, Portland, OR 97232'
      v.city     = 'Portland'
      v.state    = 'OR'
      v.zip      = '97232'
      v.capacity = 5000
    end

    # Create the event if it doesn't exist
    event = Event.find_by(slug: 'kumoricon-2026')
    unless event
      event = Event.create!(
        name:                 'Kumoricon 2026',
        description:          "Kumoricon is the Pacific Northwest's premier anime convention, held annually in Portland, Oregon. Join thousands of fans for panels, screenings, cosplay, gaming, and the largest dealer's room in the region.",
        event_type:           :hosted,
        lifecycle_status:     :published,
        venue:                venue,
        creator:              admin,
        event_date:           Date.new(2026, 11, 13),
        end_date:             Date.new(2026, 11, 15),
        start_time:           Time.zone.parse('10:00'),
        end_time:             Time.zone.parse('22:00'),
        max_attendees:        5000,
        public_rsvp_enabled:  false,
        map_enabled:          false
      )
      puts "Created Kumoricon 2026 event (slug: #{event.slug})"
    else
      puts "Kumoricon 2026 event already exists (slug: #{event.slug})"
    end

    booths = [
      { booth: '800', name: 'Kumori Cat Ears',                  category: :artist_alley },
      { booth: '302', name: '168 Dragon Trading',               category: :dealer },
      { booth: '226', name: 'Aardvark Tees',                    category: :dealer },
      { booth: '326', name: 'Akiba Doujin Unlimited',           category: :dealer },
      { booth: '506', name: 'ALICE and the PIRATES',            category: :dealer },
      { booth: '212', name: 'All Blue Anime Inc.',              category: :dealer },
      { booth: '427', name: 'Anime Palace',                     category: :dealer },
      { booth: '204', name: 'ARSENICxCYANIDE',                  category: :artist_alley },
      { booth: '223', name: "Athena's Wink",                    category: :dealer },
      { booth: '118', name: 'Awesome Anime',                    category: :dealer },
      { booth: '504', name: 'BABY, the Stars Shine Bright',     category: :dealer },
      { booth: '307', name: 'BISHIEBOX',                        category: :dealer },
      { booth: '213', name: 'Bishounen Boutique',               category: :dealer },
      { booth: '522', name: 'Black Cat Jewelry',                category: :artist_alley },
      { booth: '107', name: 'Bling Up, Inc.',                   category: :dealer },
      { booth: '811', name: 'BowenDragon1',                     category: :artist_alley },
      { booth: '413', name: 'C&L Anime',                        category: :dealer },
      { booth: '424', name: 'Cartoon Passion',                  category: :dealer },
      { booth: '805', name: 'Chronos Gifts',                    category: :artist_alley },
      { booth: '313', name: 'Collectors Universe and Anime',    category: :dealer },
      { booth: '622', name: 'Creative Scentsations',            category: :artist_alley },
      { booth: '324', name: 'Creators Guild',                   category: :dealer },
      { booth: '100', name: 'Darkmoon Faire',                   category: :dealer },
      { booth: '210', name: 'Digital Manga, Inc.',              category: :dealer },
      { booth: '602', name: 'Dunno Wat',                        category: :artist_alley },
      { booth: '122', name: 'Ejen Merchandise',                 category: :dealer },
      { booth: '308', name: 'Emerald City Comics',              category: :dealer },
      { booth: '102', name: 'FUNimation',                       category: :dealer },
      { booth: '812', name: 'Gem City Fanart',                  category: :artist_alley },
      { booth: '315', name: 'Genki Gear',                       category: :dealer },
      { booth: '415', name: 'Glitch City Records',              category: :dealer },
      { booth: '611', name: 'Hazel Creations',                  category: :artist_alley },
      { booth: '110', name: 'HIDIVE',                           category: :sponsor },
      { booth: '420', name: 'House of Anime',                   category: :dealer },
      { booth: '408', name: 'Jbox / J-List',                    category: :dealer },
      { booth: '208', name: 'Just Figures',                     category: :dealer },
      { booth: '218', name: 'Kamikaze Pop',                     category: :dealer },
      { booth: '600', name: 'KawaiiCon',                        category: :sponsor },
      { booth: '408', name: 'KumoriMarket',                     category: :dealer },
      { booth: '206', name: 'Lolita Collective',                category: :dealer },
      { booth: '311', name: 'Luna Station',                     category: :artist_alley },
      { booth: '422', name: 'Manga Planet',                     category: :dealer },
      { booth: '803', name: 'Mars Creations',                   category: :artist_alley },
      { booth: '216', name: 'Mikomi Hobby',                     category: :dealer },
      { booth: '320', name: 'Motion Import',                    category: :dealer },
      { booth: '809', name: 'Nerds & Nomsense',                 category: :artist_alley },
      { booth: '316', name: 'NISA (NIS America)',               category: :dealer },
      { booth: '127', name: 'Northwest Cosplay League',         category: :sponsor },
      { booth: '813', name: 'Nyan Industries',                  category: :artist_alley },
      { booth: '425', name: 'Otaku House',                      category: :dealer },
      { booth: '304', name: 'Pacific Anime',                    category: :dealer },
      { booth: '621', name: 'Pen Squirrel Studios',             category: :artist_alley },
      { booth: '318', name: 'Pop in a Box',                     category: :dealer },
      { booth: '802', name: 'Portland Print Lab',               category: :artist_alley },
      { booth: '116', name: 'Right Stuf Anime',                 category: :dealer },
      { booth: '310', name: 'Rug Mania',                        category: :dealer },
      { booth: '807', name: 'Sea Witch Arts',                   category: :artist_alley },
      { booth: '112', name: 'Sentai Filmworks',                 category: :dealer },
      { booth: '312', name: 'Soji Anime',                       category: :dealer },
      { booth: '614', name: 'Starfire Creations',               category: :artist_alley },
      { booth: '214', name: 'The Anime Shoppe',                 category: :dealer },
      { booth: '410', name: 'Tokyo Otaku Mode',                 category: :dealer },
      { booth: '426', name: 'Toy Anxiety',                      category: :dealer },
      { booth: '606', name: 'Twisted Pins',                     category: :artist_alley },
      { booth: '322', name: 'Viz Media',                        category: :dealer },
      { booth: '608', name: 'Wayward Muse Studio',              category: :artist_alley },
      { booth: '104', name: 'Yen Press',                        category: :dealer },
    ]

    seeded = 0
    booths.each do |b|
      vendor = Vendor.find_or_create_by!(name: b[:name]) do |v|
        v.user             = admin
        v.participant_type = :business
        v.description      = "#{b[:name]} — Kumoricon exhibitor"
        v.active           = true
      end

      next if VendorEvent.exists?(vendor: vendor, event: event)

      VendorEvent.create!(
        vendor:   vendor,
        event:    event,
        category: b[:category],
        metadata: { 'booth_number' => b[:booth], 'hall' => 'Hall C' }
      )
      seeded += 1
    end

    puts "Seeded #{seeded} vendor booths for Kumoricon 2026"
  end

  def down
    event = Event.find_by(slug: 'kumoricon-2026')
    return unless event
    event.vendor_events.destroy_all
    event.destroy
    puts "Removed Kumoricon 2026 event and vendor records"
  end
end
