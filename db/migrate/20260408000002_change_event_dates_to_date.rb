class ChangeEventDatesToDate < ActiveRecord::Migration[7.1]
  def change
    change_column :events, :event_date, :date, using: 'event_date::date'
    change_column :events, :end_date,   :date, using: 'end_date::date'
  end
end
