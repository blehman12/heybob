class FixKpopCoVendorEventMetadata < ActiveRecord::Migration[7.1]
  def up
    ve = VendorEvent.find_by(qr_token: "SAKURACON2026")
    return unless ve

    # If metadata is a String (double-encoded JSON), fix it
    if ve.metadata.is_a?(String)
      ve.update_column(:metadata, JSON.parse(ve.metadata))
      puts "Fixed SAKURACON2026 VendorEvent metadata (was double-encoded JSON)"
    else
      puts "SAKURACON2026 VendorEvent metadata is already correct (#{ve.metadata.class})"
    end
  end

  def down
    # no-op
  end
end
