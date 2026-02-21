class CreateVendors < ActiveRecord::Migration[7.1]
  def change
    create_table :vendors do |t|
      t.references :user, null: false, foreign_key: true  # owner
      t.string  :name,        null: false
      t.text    :description
      t.string  :hook_line                                 # "Free sticker with signup!"
      t.string  :website

      t.timestamps
    end
  end
end
