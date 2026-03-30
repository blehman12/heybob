class CreateGuestAppearances < ActiveRecord::Migration[7.1]
  def change
    create_table :guest_appearances do |t|
      t.references :guest, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.text    :notes
      t.integer :display_order, null: false, default: 0

      t.timestamps
    end

    add_index :guest_appearances, [:guest_id, :event_id], unique: true
  end
end
