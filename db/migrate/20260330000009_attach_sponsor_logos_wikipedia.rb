require 'open-uri'

class AttachSponsorLogosWikipedia < ActiveRecord::Migration[7.1]
  # Stable Wikimedia Commons URLs — verified March 2026
  # MAS Authentication and IZE Press have no Wikipedia logos; upload manually.
  LOGO_URLS = {
    'Aniplex'      => 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/Aniplex_logo.svg/512px-Aniplex_logo.svg.png',
    'Crunchyroll'  => 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Crunchyroll_Logo.svg/330px-Crunchyroll_Logo.svg.png',
    'Bandai Namco' => 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Bandai_Namco_Entertainment_logo.svg/500px-Bandai_Namco_Entertainment_logo.svg.png',
    'Kotobukiya'   => 'https://upload.wikimedia.org/wikipedia/commons/b/bb/Kotobukiya_Logo.webp',
    'Yen Press'    => 'https://upload.wikimedia.org/wikipedia/en/9/99/Yen_Press.png',
    'Kinokuniya'   => 'https://upload.wikimedia.org/wikipedia/commons/3/3c/Books_Kinokuniya_Logo.png',
    'Copic'        => 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Copic_brand_logo.svg/500px-Copic_brand_logo.svg.png',
    'Huion'        => 'https://upload.wikimedia.org/wikipedia/commons/2/2d/HUION_logo_blue_on_white.jpg'
  }.freeze

  CONTENT_TYPES = {
    '.png'  => 'image/png',
    '.jpg'  => 'image/jpeg',
    '.webp' => 'image/webp'
  }.freeze

  def up
    LOGO_URLS.each do |name, url|
      sponsor = Sponsor.find_by(name: name)
      unless sponsor
        puts "⚠️  #{name} — not found in DB, skipping"
        next
      end

      if sponsor.logo.attached?
        puts "⏭  #{name} — logo already attached, skipping"
        next
      end

      begin
        ext          = File.extname(URI.parse(url).path).downcase
        content_type = CONTENT_TYPES[ext] || 'image/png'
        filename     = "#{name.downcase.gsub(/[^a-z0-9]/, '_')}_logo#{ext}"

        image_io = URI.open(
          url,
          'User-Agent' => 'Mozilla/5.0 (compatible; HeyBob/1.0)',
          read_timeout: 20,
          open_timeout: 10
        )

        sponsor.logo.attach(
          io:           image_io,
          filename:     filename,
          content_type: content_type
        )
        puts "✅  #{name} — attached (#{content_type})"

      rescue => e
        puts "❌  #{name} — #{e.class}: #{e.message}"
      end
    end

    puts "\nDone. MAS Authentication and IZE Press logos need manual upload via /admin/sponsors."
  end

  def down
    Sponsor.where(name: LOGO_URLS.keys).each do |sponsor|
      sponsor.logo.purge if sponsor.logo.attached?
    end
  end
end
