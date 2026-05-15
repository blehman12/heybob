class AutoPlaceKumoriconVendorPins < ActiveRecord::Migration[7.1]
  def up
    return unless Rails.env.development? || Rails.env.production?

    event = Event.find_by(slug: 'kumoricon-2026')
    unless event
      puts "Kumoricon 2026 not found — skipping"
      return
    end

    # Zone definitions based on Kumoricon 2017 Hall C floor plan layout.
    # All values are percentages of the map image dimensions.
    #
    # Hall C (Dealer's Room) occupies the left ~58% of the image:
    #   100s: top front row
    #   200s: second row
    #   300s: third row (largest group)
    #   400s: fourth row
    #   500s: right side of dealer room / Small Press area
    #
    # Artist Alley occupies the right ~35% of the image:
    #   600s: left Artist Alley column
    #   800s: right Artist Alley column (also top section)
    zones = {
      1 => { x_start: 8.0,  x_end: 52.0, y_start: 14.0, y_end: 14.0, cols: nil },
      2 => { x_start: 8.0,  x_end: 50.0, y_start: 26.0, y_end: 26.0, cols: nil },
      3 => { x_start: 10.0, x_end: 50.0, y_start: 38.0, y_end: 38.0, cols: nil },
      4 => { x_start: 20.0, x_end: 52.0, y_start: 52.0, y_end: 52.0, cols: nil },
      5 => { x_start: 52.0, x_end: 60.0, y_start: 22.0, y_end: 40.0, cols: 1  },
      6 => { x_start: 64.0, x_end: 84.0, y_start: 28.0, y_end: 68.0, cols: 2  },
      8 => { x_start: 64.0, x_end: 84.0, y_start: 14.0, y_end: 30.0, cols: 2  },
    }

    # Group vendor_events by booth number prefix (hundreds digit)
    vendor_events = event.vendor_events.includes(:vendor).order(:id).to_a
    groups = vendor_events.group_by { |ve| ve.booth_number.to_i / 100 }

    placed = 0
    skipped = 0

    groups.each do |prefix, ves|
      zone = zones[prefix]
      unless zone
        puts "No zone defined for #{prefix}00s — skipping #{ves.map(&:booth_number).join(', ')}"
        next
      end

      # Sort by booth number within the group
      ves_sorted = ves.sort_by { |ve| ve.booth_number.to_i }
      n = ves_sorted.size

      ves_sorted.each_with_index do |ve, i|
        # Skip if already manually positioned
        if ve.map_positioned?
          skipped += 1
          next
        end

        t = n <= 1 ? 0.5 : i.to_f / (n - 1)

        x, y = if zone[:cols].nil?
          # Single horizontal row — distribute x, fixed y
          x_val = zone[:x_start] + t * (zone[:x_end] - zone[:x_start])
          [x_val, zone[:y_start]]
        elsif zone[:cols] == 1
          # Single vertical column — fixed x, distribute y
          y_val = zone[:y_start] + t * (zone[:y_end] - zone[:y_start])
          [(zone[:x_start] + zone[:x_end]) / 2.0, y_val]
        elsif zone[:cols] == 2
          # Two columns — alternate left/right, distribute y per column
          col = i % 2
          col_x = col == 0 ? zone[:x_start] : zone[:x_end]
          # Rows within each column
          rows_per_col = (n.to_f / 2).ceil
          row_in_col = i / 2
          t_col = rows_per_col <= 1 ? 0.5 : row_in_col.to_f / (rows_per_col - 1)
          y_val = zone[:y_start] + t_col * (zone[:y_end] - zone[:y_start])
          [col_x, y_val]
        end

        ve.metadata ||= {}
        ve.metadata = ve.metadata.merge('map_x' => x.round(1), 'map_y' => y.round(1))
        ve.save!
        placed += 1
      end
    end

    # Enable map on the event now that pins are placed
    event.update!(map_enabled: true)

    puts "Auto-placed #{placed} pins, skipped #{skipped} already-positioned pins"
    puts "Map enabled on Kumoricon 2026"
  end

  def down
    event = Event.find_by(slug: 'kumoricon-2026')
    return unless event
    event.vendor_events.each do |ve|
      next unless ve.map_positioned?
      ve.metadata = ve.metadata.except('map_x', 'map_y')
      ve.save!
    end
    event.update!(map_enabled: false)
    puts "Cleared auto-placed pins and disabled map"
  end
end
