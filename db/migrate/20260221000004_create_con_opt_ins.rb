class CreateConOptIns < ActiveRecord::Migration[7.1]
  def change
    create_table :con_opt_ins do |t|
      t.references :event,        null: false, foreign_key: true
      t.references :vendor_event, null: false, foreign_key: true  # first scan / referring vendor
      t.references :user,         foreign_key: true               # nullable - existing account match
      t.string     :name,         null: false
      t.string     :phone
      t.string     :email
      t.datetime   :opted_in_at,  null: false

      t.timestamps
    end

    # Deduplicate by phone per event — same phone = same person
    add_index :con_opt_ins, [:event_id, :phone], unique: true, where: "phone IS NOT NULL"
    # Deduplicate by email per event as fallback
    add_index :con_opt_ins, [:event_id, :email], unique: true, where: "email IS NOT NULL"
    add_index :con_opt_ins, :opted_in_at
  end
end
