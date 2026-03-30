class CreateVendorFollows < ActiveRecord::Migration[7.1]
  def change
    create_table :vendor_follows do |t|
      t.references :vendor, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.string :source, default: 'profile'
      t.datetime :followed_at, null: false

      t.timestamps
    end

    # Prevent duplicate follows per vendor (partial indexes allow nulls to coexist)
    add_index :vendor_follows, [:vendor_id, :phone], unique: true,
              where: "phone IS NOT NULL AND phone != ''", name: 'index_vendor_follows_on_vendor_phone'
    add_index :vendor_follows, [:vendor_id, :email], unique: true,
              where: "email IS NOT NULL AND email != ''", name: 'index_vendor_follows_on_vendor_email'
  end
end
