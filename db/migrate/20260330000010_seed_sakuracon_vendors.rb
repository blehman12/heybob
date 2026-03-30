class SeedSakuraconVendors < ActiveRecord::Migration[7.1]
  def up
    sakuracon = Event.find_by("lower(name) LIKE ?", "%sakura%con%") ||
                Event.find_by("lower(name) LIKE ?", "%sakuracon%")

    unless sakuracon
      puts "⚠️  SakuraCon event not found — skipping vendor seed"
      return
    end

    # Find or use the admin user as owner for demo vendors
    owner = User.find_by(email: 'admin@nwtg.com') || User.where(role: 1).first

    vendors = [
      # ── Artist Alley ──────────────────────────────────────────────────
      {
        name:             'Midnight Ink Studio',
        participant_type: :artist,
        description:      'Original illustration prints, stickers, and charms inspired by anime, fantasy, and dark fantasy. Every piece is hand-designed and limited run.',
        hook_line:        'Where dark fantasy meets anime aesthetics',
        website:          'https://midnightinkstudio.com',
        instagram_handle: 'midnightinkstudio',
        twitter_handle:   'midnightink_art',
        category:         :artist_alley,
        booth_number:     'AA-14',
        hall:             'Artist Alley'
      },
      {
        name:             'Pixel & Pen',
        participant_type: :artist,
        description:      'Chibi-style character art, enamel pins, and washi tape featuring original characters and fan-art of beloved anime series.',
        hook_line:        'Tiny art, big feelings',
        website:          nil,
        instagram_handle: 'pixelandpen_art',
        tiktok_handle:    'pixelandpen',
        category:         :artist_alley,
        booth_number:     'AA-27',
        hall:             'Artist Alley'
      },
      {
        name:             'Starfall Creations',
        participant_type: :artist,
        description:      'Handmade resin jewelry, keychains, and accessories with an anime and magical girl theme. Custom commissions open at the booth.',
        hook_line:        'Wear your fandom',
        website:          nil,
        instagram_handle: 'starfallcreations',
        twitter_handle:   nil,
        category:         :artist_alley,
        booth_number:     'AA-31',
        hall:             'Artist Alley'
      },

      # ── Dealer's Room ──────────────────────────────────────────────────
      {
        name:             'Tokyo Treasures',
        participant_type: :business,
        description:      'Your one-stop shop for imported Japanese anime merchandise — figures, plushies, artbooks, and limited-edition goods direct from Japan.',
        hook_line:        'Straight from Akihabara to your shelf',
        website:          'https://tokyotreasures.shop',
        instagram_handle: 'tokyotreasures_shop',
        twitter_handle:   'TokyoTreasures',
        category:         :dealer,
        booth_number:     'DR-08',
        hall:             "Dealer's Room"
      },
      {
        name:             'Arcane Collectibles',
        participant_type: :business,
        description:      'Premium anime figures, scale models, and rare collectibles. Specializing in Kotobukiya, Good Smile Company, and ALTER releases.',
        hook_line:        'Premium figures, unbeatable prices',
        website:          'https://arcanecollectibles.com',
        instagram_handle: 'arcanecollectibles',
        twitter_handle:   'ArcaneCollect',
        category:         :dealer,
        booth_number:     'DR-15',
        hall:             "Dealer's Room"
      },
      {
        name:             'Crunchyroll Store',
        participant_type: :business,
        description:      'Official Crunchyroll merchandise — apparel, accessories, and exclusives from your favorite simulcast series.',
        hook_line:        'Official merch from your favorite shows',
        website:          'https://store.crunchyroll.com',
        instagram_handle: 'crunchyroll',
        twitter_handle:   'Crunchyroll',
        category:         :dealer,
        booth_number:     'DR-01',
        hall:             "Dealer's Room"
      },
    ]

    vendors.each do |vd|
      vendor = Vendor.find_or_initialize_by(name: vd[:name])

      if vendor.new_record?
        vendor.user             = owner
        vendor.participant_type = vd[:participant_type]
        vendor.description      = vd[:description]
        vendor.hook_line        = vd[:hook_line]
        vendor.website          = vd[:website]
        vendor.instagram_handle = vd[:instagram_handle]
        vendor.twitter_handle   = vd[:twitter_handle]
        vendor.tiktok_handle    = vd[:tiktok_handle]
        vendor.save!
        puts "✅  Created vendor: #{vendor.name}"
      else
        puts "⏭  Vendor exists: #{vendor.name}"
      end

      unless VendorEvent.exists?(vendor: vendor, event: sakuracon)
        VendorEvent.create!(
          vendor:   vendor,
          event:    sakuracon,
          category: vd[:category],
          metadata: {
            'booth_number' => vd[:booth_number],
            'hall'         => vd[:hall]
          }.compact
        )
        puts "     → Linked to SakuraCon (#{vd[:booth_number]}, #{vd[:hall]})"
      end
    end

    puts "\nDone. #{Vendor.count} vendors total, #{VendorEvent.where(event: sakuracon).count} at SakuraCon."
  end

  def down
    names = ['Midnight Ink Studio', 'Pixel & Pen', 'Starfall Creations',
             'Tokyo Treasures', 'Arcane Collectibles', 'Crunchyroll Store']
    Vendor.where(name: names).destroy_all
  end
end
