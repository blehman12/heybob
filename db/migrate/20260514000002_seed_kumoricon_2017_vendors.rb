class SeedKumoricon2017Vendors < ActiveRecord::Migration[7.1]
  def up
    return unless Rails.env.development? || Rails.env.production?

    event = Event.find_by(slug: 'kumoricon-2026')
    unless event
      puts "Kumoricon 2026 event not found — skipping vendor seed"
      return
    end

    admin = User.find_by(email: 'admin@nwtg.com')
    unless admin
      puts "Admin user not found — skipping vendor seed"
      return
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
      { booth: '123', name: 'Dragonsong Forge',                 category: :dealer },
      { booth: '317', name: 'Everett Comics',                   category: :dealer },
      { booth: '405', name: 'Fake Star USA, Inc.',              category: :dealer },
      { booth: '507', name: 'FAKKU',                            category: :dealer },
      { booth: '206', name: 'Fire and Flame Sundries',          category: :dealer },
      { booth: '601', name: 'Funimation',                       category: :sponsor },
      { booth: '124', name: 'Geeky Caticorn',                   category: :dealer },
      { booth: '202', name: 'The Green Wolf',                   category: :dealer },
      { booth: '423', name: 'Hobbyfan.com',                     category: :dealer },
      { booth: '216', name: 'KikiDoodle LLC',                   category: :dealer },
      { booth: '323', name: 'Kinokuniya Book Stores',           category: :dealer },
      { booth: '802', name: 'Kiru-co Kimono',                   category: :artist_alley },
      { booth: '407', name: 'Listen Flavor',                    category: :dealer },
      { booth: '115', name: 'LunaCatz',                         category: :dealer },
      { booth: '222', name: 'The Merri Artist',                 category: :artist_alley },
      { booth: '217', name: 'New Anime',                        category: :dealer },
      { booth: '103', name: 'Ohio Kimono',                      category: :dealer },
      { booth: '623', name: 'OSI! Japan',                       category: :artist_alley },
      { booth: '314', name: 'Portland Kpop Co.',                category: :dealer },
      { booth: '225', name: 'Psycho Swami',                     category: :dealer },
      { booth: '224', name: 'Rainbow Ribbon',                   category: :dealer },
      { booth: '808', name: 'SaberForge',                       category: :artist_alley },
      { booth: '112', name: 'Sanshee LLC',                      category: :dealer },
      { booth: '203', name: "Sean's Anime & Other Things",      category: :dealer },
      { booth: '113', name: 'Shark Robot',                      category: :dealer },
      { booth: '227', name: 'Shimokawa Tailor',                 category: :dealer },
      { booth: '117', name: 'Stardreamer & Orihalcon',          category: :dealer },
      { booth: '815', name: 'Steam Aged',                       category: :artist_alley },
      { booth: '106', name: 'STL Ocarina',                      category: :dealer },
      { booth: '724', name: 'Sun Anime',                        category: :artist_alley },
      { booth: '625', name: 'Tasty Peach Studios',              category: :artist_alley },
      { booth: '322', name: 'TeeTurtle',                        category: :dealer },
      { booth: '403', name: 'Tokyo Otaku Mode',                 category: :dealer },
      { booth: '523', name: 'Toy Mandala',                      category: :artist_alley },
      { booth: '303', name: 'ToysLogic',                        category: :dealer },
      { booth: '517', name: 'ToysLogic',                        category: :dealer },
      { booth: '325', name: 'Twinbells Doujinshi & Gifts',      category: :dealer },
      { booth: '105', name: 'Unnamed Method LLC',               category: :dealer },
      { booth: '513', name: 'Uwajimaya',                        category: :dealer },
      { booth: '503', name: 'WACOM',                            category: :sponsor },
      { booth: '814', name: 'Weapons Grade Waifus',             category: :artist_alley },
      { booth: '613', name: 'Yes Anime',                        category: :artist_alley },
      { booth: '114', name: 'Yuumei',                           category: :dealer },
    ]

    created = 0
    skipped = 0

    booths.each do |b|
      vendor = Vendor.find_by(name: b[:name])
      unless vendor
        # Create a placeholder vendor owned by admin
        vendor = Vendor.create!(
          name: b[:name],
          user: admin,
          participant_type: b[:category] == :artist_alley ? :artist : :business,
          description: "Kumoricon 2017 exhibitor — booth #{b[:booth]}"
        )
      end

      ve = VendorEvent.find_by(vendor: vendor, event: event)
      if ve
        skipped += 1
        next
      end

      VendorEvent.create!(
        vendor: vendor,
        event: event,
        category: b[:category],
        metadata: { 'booth_number' => b[:booth], 'hall' => 'Hall C' }
      )
      created += 1
    end

    puts "Kumoricon 2017 vendors: #{created} created, #{skipped} skipped"
  end

  def down
    event = Event.find_by(slug: 'kumoricon-2026')
    return unless event
    event.vendor_events.destroy_all
  end
end
