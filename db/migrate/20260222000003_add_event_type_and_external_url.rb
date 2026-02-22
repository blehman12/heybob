class AddEventTypeAndExternalUrl < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :event_type, :integer, default: 0, null: false
    add_column :events, :external_url, :string
    add_index  :events, :event_type

    # venue and capacity can be blank for reference events
    change_column_null :events, :max_attendees, true
  end
end
