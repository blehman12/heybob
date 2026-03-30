class CreateGuests < ActiveRecord::Migration[7.1]
  def change
    create_table :guests do |t|
      t.string  :name,             null: false
      t.text    :bio
      t.integer :guest_type,       null: false, default: 0
      t.string  :website
      t.string  :instagram_handle
      t.string  :twitter_handle
      t.string  :tiktok_handle
      t.string  :youtube_handle
      t.boolean :is_active,        null: false, default: true

      t.timestamps
    end

    add_index :guests, :guest_type
    add_index :guests, :is_active
  end
end
