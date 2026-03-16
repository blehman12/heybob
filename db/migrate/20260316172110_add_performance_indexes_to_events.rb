class AddPerformanceIndexesToEvents < ActiveRecord::Migration[7.1]
  def change
    add_index :events, :venue_id   unless index_exists?(:events, :venue_id)
    add_index :events, :creator_id unless index_exists?(:events, :creator_id)
    unless index_exists?(:event_participants, [:event_id, :rsvp_status])
      add_index :event_participants, [:event_id, :rsvp_status],
                name: 'index_event_participants_on_event_id_and_rsvp_status'
    end
    unless index_exists?(:event_participants, [:event_id, :role])
      add_index :event_participants, [:event_id, :role],
                name: 'index_event_participants_on_event_id_and_role'
    end
  end
end
