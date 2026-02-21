class CreateVendorEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :vendor_events do |t|
      t.references :vendor, null: false, foreign_key: true
      t.references :event,  null: false, foreign_key: true
      t.text       :metadata,      null: false, default: '{}'  # jsonb in production (Postgres), text in dev (SQLite)
      t.string     :qr_token,      null: false               # unique per vendor per event
      t.boolean    :is_active,     null: false, default: true
      t.integer    :display_order, null: false, default: 0   # feed ordering

      t.timestamps
    end

    # A vendor can only participate in an event once
    add_index :vendor_events, [:vendor_id, :event_id], unique: true
    add_index :vendor_events, :qr_token, unique: true
  end
end
