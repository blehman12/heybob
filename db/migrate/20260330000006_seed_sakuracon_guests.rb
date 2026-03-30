class SeedSakuraconGuests < ActiveRecord::Migration[7.1]
  def up
    guests = [
      # ── Animation Industry ──────────────────────────────────────────
      {
        name:       'Masako Sato',
        guest_type: 2, # industry
        bio:        'Animation Director and Episode Director, best known as director of TRIGUN STAMPEDE. A key creative force behind some of anime\'s most visually striking recent productions.'
      },
      {
        name:       'Naoya Nakayama',
        guest_type: 2, # industry
        bio:        'Director, Animation Director, and Storyboard Artist with credits across multiple acclaimed anime series. Known for his precise and expressive visual storytelling.'
      },
      {
        name:       'Yoshihiro Watanabe',
        guest_type: 2, # industry
        bio:        'Producer with credits on LEVIATHAN, BEASTARS, and TRIGUN STAMPEDE. Brings a wealth of experience from some of anime\'s most celebrated recent productions.'
      },
      {
        name:       'Hiroshi Nagahama',
        guest_type: 2, # industry
        bio:        'Animator and director who began his career at the legendary Madhouse Studio. Known for his distinctive artistic sensibility and contributions to landmark anime productions.'
      },

      # ── English Voice Actors ────────────────────────────────────────
      {
        name:       'Bill Butts',
        guest_type: 0, # voice_actor
        bio:        'Voice and film actor with a diverse portfolio spanning anime dubbing and live-action projects.'
      },
      {
        name:       'Brittney Karbowski',
        guest_type: 0, # voice_actor
        bio:        'Beloved voice actress known for roles in Fairy Tail and My Hero Academia, with a dedicated fanbase across the anime community.'
      },
      {
        name:       'Cassandra Lee Morris',
        guest_type: 0, # voice_actor
        bio:        'LA-based voice actress with nearly 300 character roles to her name, spanning anime, video games, and animation.'
      },
      {
        name:       'Chris Hackney',
        guest_type: 0, # voice_actor
        bio:        'Versatile American voice actor from Florida with an extensive catalog of anime and video game roles.'
      },
      {
        name:       'David Matranga',
        guest_type: 0, # voice_actor
        bio:        'Best known as the English voice of Shoto Todoroki in My Hero Academia. A fan-favorite presence at conventions across the country.'
      },
      {
        name:       'Faye Mata',
        guest_type: 0, # voice_actor
        bio:        'Voice actress and gaming advocate with a passion for connecting fans to the worlds they love through performance.'
      },
      {
        name:       'Jill Harris',
        guest_type: 0, # voice_actor
        bio:        'Voice actress who began her career at age 15 and has since built an impressive body of work in anime dubbing and beyond.'
      },
      {
        name:       'Jordan Dash Cruz',
        guest_type: 0, # voice_actor
        bio:        'Actor and director from Texas with credits in both voice acting and on-screen performance across anime and original productions.'
      },
      {
        name:       'Kari Wahlgren',
        guest_type: 0, # voice_actor
        bio:        'Acclaimed voice actress whose career began with the iconic role of Haruko in FLCL. A fan-favorite with hundreds of anime and gaming credits.'
      },
      {
        name:       'Kelsey Cruz',
        guest_type: 0, # voice_actor
        bio:        'Actor and singer from Seattle with roles spanning voice acting, anime dubbing, and musical performance.'
      },
      {
        name:       'Kristen McGuire',
        guest_type: 0, # voice_actor
        bio:        'Voice actor and ADR director with over 350 credits. Brings both performance and behind-the-scenes expertise to the world of anime dubbing.'
      },
      {
        name:       'Lauren Landa',
        guest_type: 0, # voice_actor
        bio:        'LA-based voice actress with over 100 anime and video game titles to her name, known for emotionally compelling performances.'
      },
      {
        name:       'Lisa Reimold',
        guest_type: 0, # voice_actor
        bio:        'Voice actress recognized for her roles in DANDADAN and the Fire Emblem franchise, with a growing presence in anime and gaming.'
      },
      {
        name:       'Mallorie Rodak',
        guest_type: 0, # voice_actor
        bio:        'Voice actress nominated for Breakthrough Voice Actress in 2014, with a career spanning anime dubbing and original animation.'
      },
      {
        name:       'Sonny Strait',
        guest_type: 0, # voice_actor
        bio:        'Iconic voice of Krillin in Dragon Ball Z, with decades of beloved roles in anime dubbing and a passion for fan engagement at conventions.'
      },

      # ── Japanese Voice Actors ───────────────────────────────────────
      {
        name:       'Emi Nitta',
        guest_type: 0, # voice_actor
        bio:        'Japanese voice actress who debuted in 2010 and is best known for her beloved role as Honoka Kosaka in Love Live!, one of the most iconic idol anime franchises.'
      },
      {
        name:       'Haruki Ishiya',
        guest_type: 0, # voice_actor
        bio:        'Japanese voice actor affiliated with Osawa Office, with a growing presence in the anime industry.'
      },

      # ── Musicians ───────────────────────────────────────────────────
      {
        name:       'Blue Encount',
        guest_type: 1, # musician
        bio:        'A 4-piece rock band hailing from Kumamoto in southern Japan, known for high-energy performances and anime tie-in tracks that have captured audiences worldwide.'
      },
      {
        name:       'SCANDAL',
        guest_type: 1, # musician
        bio:        'All-female Japanese rock band formed in 2006, winners of the Record Award for Best Newcomer in 2009. Known for their dynamic performances and iconic anime theme songs.'
      },

      # ── Performers & Designers ──────────────────────────────────────
      {
        name:       'Karin Moriguchi',
        guest_type: 3, # artist
        bio:        'Fashion designer creating "kawaii" Taisho-Roman-inspired clothing that blends traditional Japanese aesthetics with contemporary fashion and anime culture.'
      },
      {
        name:       'Oriana Peron',
        guest_type: 4, # performer
        bio:        'Drag performer who has been combining cosplay with stage performance since 2006, creating dazzling character-based drag that celebrates anime and pop culture.'
      }
    ]

    now = Time.current

    guests.each do |attrs|
      next if Guest.exists?(name: attrs[:name])
      Guest.create!(
        name:       attrs[:name],
        guest_type: attrs[:guest_type],
        bio:        attrs[:bio],
        is_active:  true,
        created_at: now,
        updated_at: now
      )
    end

    # Link all guests to the SakuraCon 2026 event if it exists
    sakuracon = Event.find_by("lower(name) LIKE ?", "%sakura%con%") ||
                Event.find_by("lower(name) LIKE ?", "%sakuracon%")

    if sakuracon
      Guest.all.each do |guest|
        unless GuestAppearance.exists?(guest: guest, event: sakuracon)
          GuestAppearance.create!(guest: guest, event: sakuracon)
        end
      end
    end
  end

  def down
    guest_names = [
      'Masako Sato', 'Naoya Nakayama', 'Yoshihiro Watanabe', 'Hiroshi Nagahama',
      'Bill Butts', 'Brittney Karbowski', 'Cassandra Lee Morris', 'Chris Hackney',
      'David Matranga', 'Faye Mata', 'Jill Harris', 'Jordan Dash Cruz',
      'Kari Wahlgren', 'Kelsey Cruz', 'Kristen McGuire', 'Lauren Landa',
      'Lisa Reimold', 'Mallorie Rodak', 'Sonny Strait', 'Emi Nitta', 'Haruki Ishiya',
      'Blue Encount', 'SCANDAL', 'Karin Moriguchi', 'Oriana Peron'
    ]
    Guest.where(name: guest_names).destroy_all
  end
end
