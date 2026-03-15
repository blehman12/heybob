class FixSakuraconDateAndCategories < ActiveRecord::Migration[7.1]
  def up
    # The previous migration (20260313000001) used slug "sakuracon-2026" but the
    # actual slug is "sakuracon-2026-2026" because the name "Sakuracon 2026"
    # already contains the year, causing double-appending during slug generation.
    event = Event.find_by(slug: "sakuracon-2026-2026")

    unless event
      puts "SakuraCon 2026 not found — skipping"
      return
    end

    # Fix date: SakuraCon 2026 runs April 3–6 at Washington State Convention Center
    event.update_columns(
      event_date:    DateTime.new(2026, 4, 3, 10, 0, 0),
      rsvp_deadline: DateTime.new(2026, 3, 31, 23, 59, 0)
    )
    puts "  Updated SakuraCon date to April 3, 2026 (RSVP deadline March 31)"

    # Tag with appropriate categories
    tag_slugs = %w[anime pop-culture convention pacific-northwest]
    tag_slugs.each do |slug|
      cat = Category.find_by(slug: slug)
      if cat
        Categorization.find_or_create_by!(
          categorizable: event,
          category: cat
        )
        puts "  Tagged: #{cat.name}"
      else
        puts "  Category not found: #{slug} — skipping"
      end
    end
  end

  def down
    event = Event.find_by(slug: "sakuracon-2026-2026")
    return unless event

    event.update_columns(
      event_date:    DateTime.new(2026, 5, 22, 9, 0, 0),
      rsvp_deadline: DateTime.new(2026, 5, 15, 23, 59, 0)
    )

    %w[anime pop-culture convention pacific-northwest].each do |slug|
      cat = Category.find_by(slug: slug)
      Categorization.where(categorizable: event, category: cat).delete_all if cat
    end
  end
end
