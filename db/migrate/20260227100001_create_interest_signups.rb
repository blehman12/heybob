class CreateInterestSignups < ActiveRecord::Migration[7.1]
  def change
    create_table :interest_signups do |t|
      t.string :name,   null: false
      t.string :email
      t.string :phone
      t.string :source   # e.g. "sakuracon-flyer", "plm-website", "events-page"
      t.text   :notes    # optional free-text from the visitor

      t.timestamps
    end

    add_index :interest_signups, :email
    add_index :interest_signups, :created_at
  end
end
