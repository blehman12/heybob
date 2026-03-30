class CreateSponsors < ActiveRecord::Migration[7.1]
  def change
    create_table :sponsors do |t|
      t.string  :name,          null: false
      t.text    :description
      t.string  :website
      t.integer :tier,          null: false, default: 4
      t.integer :display_order, null: false, default: 0
      t.boolean :is_active,     null: false, default: true

      t.timestamps
    end

    add_index :sponsors, :tier
    add_index :sponsors, :is_active
  end
end
