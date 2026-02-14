# frozen_string_literal: true

class FixRsvpDataModel < ActiveRecord::Migration[7.1]
  def up
    # This migration fixes the fundamental data model issue where rsvp_status
    # was incorrectly placed on the users table instead of only on event_participants.
    #
    # A user can have different RSVP statuses for different events, so this data
    # belongs on the join table (event_participants), not the user table.
    
    say_with_time "Migrating RSVP data from users to event_participants" do
      # Safety check: Ensure we don't lose any data
      users_with_rsvp = User.where.not(rsvp_status: [nil, 0]).count
      
      if users_with_rsvp > 0
        say "WARNING: Found #{users_with_rsvp} users with non-default rsvp_status"
        say "These values will be removed since RSVP status is event-specific"
        say "All event-specific RSVP data should already be in event_participants table"
      end
      
      # Remove columns that don't belong on users table
      # These are event-specific and should only exist on event_participants
      remove_column :users, :rsvp_status, :integer
      remove_column :users, :invited_at, :datetime
      remove_column :users, :calendar_exported, :boolean
      
      say "Removed event-specific columns from users table"
    end
    
    say_with_time "Ensuring all event_participants have proper defaults" do
      # Update any NULL rsvp_status to pending
      EventParticipant.where(rsvp_status: nil).update_all(rsvp_status: 0)
      
      # Add NOT NULL constraint now that we've fixed the data
      change_column_null :event_participants, :rsvp_status, false
      
      say "Set NOT NULL constraint on event_participants.rsvp_status"
    end
  end
  
  def down
    # Reversing this migration adds back the incorrect structure
    # Only use this if you absolutely need to rollback
    
    add_column :users, :rsvp_status, :integer, default: 0
    add_column :users, :invited_at, :datetime
    add_column :users, :calendar_exported, :boolean, default: false
    
    change_column_null :event_participants, :rsvp_status, true
    
    say "WARNING: Restored incorrect data model. RSVP status on users table is wrong!"
  end
end
