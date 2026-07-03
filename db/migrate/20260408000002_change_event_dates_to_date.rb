class ChangeEventDatesToDate < ActiveRecord::Migration[7.1]
  def change
    # :using is Postgres-only; SQLite rewrites the table and casts implicitly
    if connection.adapter_name =~ /postgres/i
      change_column :events, :event_date, :date, using: 'event_date::date'
      change_column :events, :end_date,   :date, using: 'end_date::date'
    else
      change_column :events, :event_date, :date
      change_column :events, :end_date,   :date
    end
  end
end
