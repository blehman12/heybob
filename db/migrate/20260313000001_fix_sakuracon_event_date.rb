class FixSakuraconEventDate < ActiveRecord::Migration[7.1]
  def up
    event = Event.find_by(slug: "sakuracon-2026")
    if event
      event.update!(
        event_date: DateTime.new(2026, 4, 3, 10, 0, 0),
        name: "SakuraCon 2026"
      )
      puts "Updated SakuraCon 2026 event date to April 3, 2026"
    else
      puts "SakuraCon 2026 event not found — skipping"
    end
  end

  def down
    event = Event.find_by(slug: "sakuracon-2026")
    event&.update!(event_date: DateTime.new(2026, 3, 27, 10, 0, 0))
  end
end
