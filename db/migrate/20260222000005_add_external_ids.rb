class AddExternalIds < ActiveRecord::Migration[7.1]
  def change
    add_column :events,    :external_id, :string
    add_column :vendors,   :external_id, :string
    add_column :categories,:external_id, :string
    add_column :users,     :external_id, :string

    add_index :events,     :external_id, unique: true
    add_index :vendors,    :external_id, unique: true
    add_index :categories, :external_id, unique: true
    add_index :users,      :external_id, unique: true
  end
end
