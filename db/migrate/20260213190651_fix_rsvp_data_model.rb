# frozen_string_literal: true

class FixRsvpDataModel < ActiveRecord::Migration[7.1]
  def up
    # This migration fixes the fundamental data model issue where rsvp_status
    # was incorrectly placed on the users table instead of only on event_participants.
    #
    # A user can have different RSVP statuses for different events, so this data
    # belongs on the join table (event_participants), not the user table.
    
    say_with_time "Migrating RSVP data from users to event_participants" do
      # Only remove columns if they actually exist (safe for fresh databases)
      if column_exists?(:users, :rsvp_status)
        remove_column :users, :rsvp_status, :integer
        say "Removed rsvp_status from users table"
      else
        say "rsvp_status column not present on users table, skipping"
      end

      if column_exists?(:users, :invited_at)
        remove_column :users, :invited_at, :datetime
        say "Removed invited_at from users table"
      else
        say "invited_at column not present on users table, skipping"
      end

      if column_exists?(:users, :calendar_exported)
        remove_column :users, :calendar_exported, :boolean
        say "Removed calendar_exported from users table"
      else
        say "calendar_exported column not present on users table, skipping"
      end
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
