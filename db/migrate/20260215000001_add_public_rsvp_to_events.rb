class AddPublicRsvpToEvents < ActiveRecord::Migration[7.1]
  def change
    # Add slug for public URLs
    add_column :events, :slug, :string
    add_index :events, :slug, unique: true
    
    # Add public RSVP enable flag
    add_column :events, :public_rsvp_enabled, :boolean, default: false
    
    # Make user_id optional for guest RSVPs
    change_column_null :event_participants, :user_id, true
    
    # Add guest fields for non-authenticated RSVPs
    add_column :event_participants, :guest_name, :string
    add_column :event_participants, :guest_email, :string
    add_column :event_participants, :guest_phone, :string
    add_column :event_participants, :is_guest, :boolean, default: false
    
    add_index :event_participants, :guest_email
  end
end
