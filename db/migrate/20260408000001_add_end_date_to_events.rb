class AddEndDateToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :end_date, :datetime, null: true
  end
end
