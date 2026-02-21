class CreateBroadcastReceipts < ActiveRecord::Migration[7.1]
  def change
    create_table :broadcast_receipts do |t|
      t.references :broadcast,   null: false, foreign_key: true
      t.references :con_opt_in,  null: false, foreign_key: true
      t.integer    :status,      null: false, default: 0   # enum: pending, delivered, failed
      t.datetime   :delivered_at

      t.timestamps
    end

    # One receipt per opt-in per broadcast
    add_index :broadcast_receipts, [:broadcast_id, :con_opt_in_id], unique: true
    add_index :broadcast_receipts, :status
  end
end
