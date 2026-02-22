class BackfillExternalIds < ActiveRecord::Migration[7.1]
  def up
    [User, Event, Vendor, Category].each do |model|
      model.where(external_id: nil).find_each do |record|
        record.update_columns(external_id: SecureRandom.uuid)
      end
    end
  end

  def down
    # no-op — UUIDs are additive, no reason to remove them
  end
end
