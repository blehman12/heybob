require 'open-uri'

# Fetch sponsor logos from Clearbit Logo API and attach via ActiveStorage.
# Run on Railway: railway run bundle exec rails runner db/seeds/attach_sponsor_logos.rb

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
  'IZE'                => 'ize-press.com',
  'Concept Garage'     => nil,
  'Mox Valley Games'   => nil
}.freeze

results = { attached: 0, skipped: 0, failed: 0 }

puts "Attaching sponsor logos from Clearbit...\n\n"

Sponsor.order(:name).each do |sponsor|
  domain = SPONSOR_DOMAINS[sponsor.name]

  if domain.nil?
    puts "⏭  #{sponsor.name} — no domain configured, skipping"
    results[:skipped] += 1
    next
  end

  if sponsor.logo.attached?
    puts "⏭  #{sponsor.name} — logo already attached, skipping"
    results[:skipped] += 1
    next
  end

  url = "https://logo.clearbit.com/#{domain}"

  begin
    image_io = URI.open(
      url,
      'User-Agent' => 'HeyBob/1.0',
      read_timeout: 15,
      open_timeout: 10
    )

    content_type = image_io.content_type.presence || 'image/png'
    filename     = "#{domain.gsub(/[^a-z0-9]/, '_')}_logo.png"

    sponsor.logo.attach(
      io:           image_io,
      filename:     filename,
      content_type: content_type
    )

    puts "✅  #{sponsor.name} — attached (#{content_type})"
    results[:attached] += 1

  rescue OpenURI::HTTPError => e
    puts "❌  #{sponsor.name} — HTTP error: #{e.message} (#{url})"
    results[:failed] += 1
  rescue => e
    puts "❌  #{sponsor.name} — #{e.class}: #{e.message}"
    results[:failed] += 1
  end
end

puts "\n#{'─' * 40}"
puts "✅ Attached : #{results[:attached]}"
puts "⏭  Skipped  : #{results[:skipped]}"
puts "❌ Failed   : #{results[:failed]}"
puts "\nDone. Review /admin/sponsors to verify logos."
