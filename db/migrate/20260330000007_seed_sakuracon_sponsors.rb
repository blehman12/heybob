class SeedSakuraconSponsors < ActiveRecord::Migration[7.1]
  def up
    # NOTE: SakuraCon does not publish official tier levels on their website.
    # Tiers below are estimated based on brand size/industry presence.
    # Confirm actual tier levels with SakuraCon before making public-facing.
    sponsors = [
      # ── Estimated Presenting Tier ───────────────────────────────────
      {
        name:          'Aniplex',
        tier:          1, # presenting
        website:       'https://www.aniplex.us',
        description:   'Aniplex is a leading anime production and distribution company, bringing some of the most beloved anime series to fans worldwide.',
        display_order: 1
      },
      {
        name:          'Crunchyroll',
        tier:          1, # presenting
        website:       'https://www.crunchyroll.com',
        description:   'Crunchyroll is the world\'s largest anime streaming platform, delivering the latest simulcast episodes and a massive library of classic series to fans everywhere.',
        display_order: 2
      },

      # ── Estimated Gold Tier ─────────────────────────────────────────
      {
        name:          'Bandai Namco',
        tier:          2, # gold
        website:       'https://www.bandainamcoent.com',
        description:   'Bandai Namco Entertainment is a global leader in anime-based games, collectibles, and merchandise, bringing iconic franchises to life for fans worldwide.',
        display_order: 1
      },
      {
        name:          'Kotobukiya',
        tier:          2, # gold
        website:       'https://www.kotobukiya.co.jp/en/',
        description:   'Kotobukiya is a renowned Japanese manufacturer of high-quality anime and gaming figures, model kits, and collectibles.',
        display_order: 2
      },
      {
        name:          'Yen Press',
        tier:          2, # gold
        website:       'https://yenpress.com',
        description:   'Yen Press is a leading publisher of manga and light novels in English, bringing beloved Japanese stories to readers across North America.',
        display_order: 3
      },

      # ── Estimated Silver Tier ───────────────────────────────────────
      {
        name:          'Kinokuniya',
        tier:          3, # silver
        website:       'https://usa.kinokuniya.com',
        description:   'Kinokuniya is a beloved Japanese bookstore chain with a Seattle location, offering manga, light novels, art books, and Japanese imports.',
        display_order: 1
      },
      {
        name:          'Copic',
        tier:          3, # silver
        website:       'https://copic.jp/en/',
        description:   'Copic markers are the professional-grade illustration tools of choice for manga artists and illustrators worldwide.',
        display_order: 2
      },
      {
        name:          'Huion',
        tier:          3, # silver
        website:       'https://www.huion.com',
        description:   'Huion creates professional-grade digital drawing tablets and pen displays used by artists and illustrators across the globe.',
        display_order: 3
      },
      {
        name:          'MAS Authentication',
        tier:          3, # silver
        website:       'https://www.masauthentication.com',
        description:   'MAS Authentication provides professional authentication and grading services for anime and pop culture collectibles.',
        display_order: 4
      },

      # ── Estimated General Tier ──────────────────────────────────────
      {
        name:          'IZE',
        tier:          4, # general
        website:       'https://yenpress.com/ize-press',
        description:   'IZE is a Yen Press imprint publishing Korean webtoons and manhwa in print for English-language readers.',
        display_order: 1
      },
      {
        name:          'Concept Garage',
        tier:          4, # general
        website:       nil,
        description:   'Concept Garage is a supporter of Sakura-Con and the Pacific Northwest anime community.',
        display_order: 2
      },
      {
        name:          'Mox Valley Games',
        tier:          4, # general
        website:       nil,
        description:   'Mox Valley Games is a local gaming retailer and supporter of the Pacific Northwest gaming and anime community.',
        display_order: 3
      }
    ]

    now = Time.current

    sponsors.each do |attrs|
      next if Sponsor.exists?(name: attrs[:name])
      Sponsor.create!(
        name:          attrs[:name],
        tier:          attrs[:tier],
        website:       attrs[:website],
        description:   attrs[:description],
        display_order: attrs[:display_order],
        is_active:     true,
        created_at:    now,
        updated_at:    now
      )
    end

    # Link all sponsors to the SakuraCon 2026 event if it exists
    sakuracon = Event.find_by("lower(name) LIKE ?", "%sakura%con%") ||
                Event.find_by("lower(name) LIKE ?", "%sakuracon%")

    if sakuracon
      Sponsor.all.each do |sponsor|
        unless SponsorEvent.exists?(sponsor: sponsor, event: sakuracon)
          SponsorEvent.create!(sponsor: sponsor, event: sakuracon)
        end
      end
    end
  end

  def down
    sponsor_names = %w[
      Aniplex Crunchyroll Kotobukiya Bandai\ Namco Yen\ Press
      Kinokuniya Copic Huion MAS\ Authentication IZE Concept\ Garage Mox\ Valley\ Games
    ]
    Sponsor.where(name: sponsor_names).destroy_all
  end
end
