class CreateBroadcasts < ActiveRecord::Migration[7.1]
  def change
    create_table :broadcasts do |t|
      t.references :vendor_event, null: false, foreign_key: true
      t.text       :message,       null: false
      t.integer    :channel,       null: false, default: 0  # enum: sms, email, feed
      t.integer    :scope,         null: false, default: 0  # enum: booth_visitors, entire_con
      t.datetime   :sent_at
      t.integer    :recipient_count, default: 0             # snapshot at send time

      t.timestamps
    end

    add_index :broadcasts, :sent_at
    add_index :broadcasts, [:vendor_event_id, :sent_at]
  end
end
