namespace :demo do
  desc "Seed a demo VendorEvent with a known QR token for Twilio verification"
  task seed_optin: :environment do
    puts "Seeding demo vendor event for Twilio opt-in verification..."

    QR_TOKEN = "SAKURACON2026"

    # Short-circuit if already done
    if VendorEvent.exists?(qr_token: QR_TOKEN)
      puts "  VendorEvent already exists with token: #{QR_TOKEN}"
      puts "  URL: https://heybob-production.up.railway.app/join/#{QR_TOKEN}"
      next
    end

    # Find a suitable owner user
    user = User.find_by(email: "blehman12@comcast.net") ||
           User.where(role: 1).first ||
           User.first

    abort "ERROR: No user found. Create a user first." if user.nil?
    puts "  Using user: #{user.email}"

    # Find or create the SakuraCon event
    event = Event.find_by(slug: "sakuracon-2026") ||
            Event.where("name ILIKE ?", "%sakura%").first ||
            Event.create!(
              name: "SakuraCon 2026",
              slug: "sakuracon-2026",
              event_date: DateTime.new(2026, 3, 27, 10, 0, 0),
              lifecycle_status: 1,
              creator_id: user.id
            )
    puts "  Using event: #{event.name}"

    # Find or create a demo vendor
    vendor = Vendor.find_by(name: "Portland KPOP CO") ||
             Vendor.create!(
               name: "Portland KPOP CO",
               user: user,
               participant_type: :business,
               description: "Portland's premier KPOP merchandise vendor"
             )
    puts "  Using vendor: #{vendor.name}"

    # Create the VendorEvent with our known QR token
    # We skip the auto-generate callback because qr_token is pre-set
    ve = VendorEvent.new(
      vendor:   vendor,
      event:    event,
      category: :dealer,
      qr_token: QR_TOKEN,
      metadata: { "booth_number" => "247", "hall" => "Main Hall" }.to_json
    )
    ve.save!
    puts "  Created VendorEvent with token: #{QR_TOKEN}"

    url = "https://heybob-production.up.railway.app/join/#{QR_TOKEN}"
    puts ""
    puts "✅ Done! Your Twilio opt-in verification URL is:"
    puts "   #{url}"
    puts ""
    puts "Use this URL in the Twilio toll-free verification form."
  end
end
