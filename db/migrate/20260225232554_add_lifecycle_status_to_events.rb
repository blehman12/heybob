class AddLifecycleStatusToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :lifecycle_status, :integer, default: 1, null: false
    add_index :events, :lifecycle_status
  end
end
