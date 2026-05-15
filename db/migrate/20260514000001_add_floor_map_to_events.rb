class AddFloorMapToEvents < ActiveRecord::Migration[7.1]
  def change
    # floor_map is handled by Active Storage — no column needed
    # map_enabled flag controls whether the public map tab is shown
    add_column :events, :map_enabled, :boolean, default: false, null: false
  end
end
