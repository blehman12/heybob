# db/migrate/20260225000003_seed_vendor_events.rb
# Creates vendor event appearances for Sakuracon 2026.
# Safe to re-run — skips if vendor_event already exists.
class SeedVendorEvents < ActiveRecord::Migration[7.1]
  def up
    event = Event.find_by(slug: 'sakuracon-2026-2026')
    unless event
      puts "  SKIP: sakuracon-2026-2026 not found"
      return
    end

    [
      { vendor_name: 'CoreTech Solutions',      category: :dealer,    booth: 'D-01', hall: 'Exhibit Hall' },
      { vendor_name: 'Enterprise Solutions Inc', category: :sponsor,   booth: 'S-01', hall: 'Main Hall' },
      { vendor_name: 'PLM Consulting Group',     category: :exhibitor, booth: 'E-05', hall: 'Main Hall' },
      { vendor_name: 'Tech Systems LLC',         category: :dealer,    booth: 'D-12', hall: 'Exhibit Hall' },
    ].each do |vd|
      vendor = Vendor.find_by(name: vd[:vendor_name])
      unless vendor
        puts "  SKIP: vendor '#{vd[:vendor_name]}' not found"
        next
      end

      next if VendorEvent.exists?(vendor: vendor, event: event)

      ve = VendorEvent.create!(
        vendor:   vendor,
        event:    event,
        category: vd[:category],
        metadata: { 'booth_number' => vd[:booth], 'hall' => vd[:hall] }
      )
      puts "  Created VendorEvent: #{vendor.name} @ #{event.name} (#{vd[:category]}, #{vd[:booth]})"
    end
  end

  def down
    # no-op
  end
end
