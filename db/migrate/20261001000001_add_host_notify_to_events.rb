class AddHostNotifyToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :notify_host_on_rsvp, :boolean, default: false, null: false
    add_column :events, :host_notify_email, :string
  end
end
