class CreateVendorOptIns < ActiveRecord::Migration[7.1]
  def change
    # Join table — handles visitor scanning at multiple booths
    create_table :vendor_opt_ins do |t|
      t.references :vendor_event, null: false, foreign_key: true
      t.references :con_opt_in,   null: false, foreign_key: true
      t.datetime   :scanned_at,   null: false

      t.timestamps
    end

    # A visitor can only be associated with a vendor once per event
    add_index :vendor_opt_ins, [:vendor_event_id, :con_opt_in_id], unique: true
  end
end
