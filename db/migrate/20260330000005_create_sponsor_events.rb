class CreateSponsorEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :sponsor_events do |t|
      t.references :sponsor, null: false, foreign_key: true
      t.references :event,   null: false, foreign_key: true
      t.integer :display_order, null: false, default: 0

      t.timestamps
    end

    add_index :sponsor_events, [:sponsor_id, :event_id], unique: true
  end
end
