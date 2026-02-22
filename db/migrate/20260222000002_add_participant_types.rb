class AddParticipantTypes < ActiveRecord::Migration[7.1]
  def change
    # Vendor gets participant_type and social handles
    add_column :vendors, :participant_type, :integer, default: 0, null: false
    add_column :vendors, :instagram_handle, :string
    add_column :vendors, :twitter_handle, :string
    add_column :vendors, :tiktok_handle, :string

    # VendorEvent gets category (what role they play at THIS event)
    add_column :vendor_events, :category, :integer, default: 0, null: false

    add_index :vendors, :participant_type
    add_index :vendor_events, :category
  end
end
