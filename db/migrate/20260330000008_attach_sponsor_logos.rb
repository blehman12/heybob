require 'open-uri'

class AttachSponsorLogos < ActiveRecord::Migration[7.1]
  SPONSOR_DOMAINS = {
    'Aniplex'            => 'aniplex.us',
    'Crunchyroll'        => 'crunchyroll.com',
    'Bandai Namco'       => 'bandainamcoent.com',
    'Kotobukiya'         => 'kotobukiya.co.jp',
    'Yen Press'          => 'yenpress.com',
    'Kinokuniya'         => 'kinokuniya.com',
    'Copic'              => 'copic.jp',
    'Huion'              => 'huion.com',
    'MAS Authentication' => 'masauthentication.com',
    'IZE'                => 'ize-press.com'
  }.freeze

  def up
    SPONSOR_DOMAINS.each do |name, domain|
      sponsor = Sponsor.find_by(name: name)
      next unless sponsor
      next if sponsor.logo.attached?

      begin
        image_io = URI.open(
          "https://logo.clearbit.com/#{domain}",
          'User-Agent' => 'HeyBob/1.0',
          read_timeout: 15,
          open_timeout: 10
        )
        sponsor.logo.attach(
          io:           image_io,
          filename:     "#{domain.gsub(/[^a-z0-9]/, '_')}_logo.png",
          content_type: image_io.content_type.presence || 'image/png'
        )
        puts "✅  #{name} logo attached"
      rescue => e
        puts "⚠️  #{name} skipped — #{e.message}"
        # Non-fatal: don't block the migration if Clearbit is unavailable
      end
    end
  end

  def down
    Sponsor.where(name: SPONSOR_DOMAINS.keys).each do |sponsor|
      sponsor.logo.purge if sponsor.logo.attached?
    end
  end
end
