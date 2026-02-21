class CreateVendorUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :vendor_users do |t|
      t.references :vendor, null: false, foreign_key: true
      t.references :user,   null: false, foreign_key: true
      t.datetime   :added_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    # A user can only be added to a vendor once
    add_index :vendor_users, [:vendor_id, :user_id], unique: true
  end
end
