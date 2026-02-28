class CategorizeDemoEvents < ActiveRecord::Migration[7.1]
  CATEGORIZATIONS = {
    "Pacific Northwest PLM Summit 2025" => %w[plm-tools conference pacific-northwest engineers],
    "Windchill User Group – Portland Chapter" => %w[plm-tools-windchill user-group pacific-northwest engineers],
    "Creo Power Users Workshop – Seattle" => %w[plm-tools-creo training pacific-northwest engineers],
    "PTC LiveWorx 2026 – Seattle Preview Night" => %w[plm-tools meetup pacific-northwest engineers],
    "ERP & PLM Integration Forum – Pacific Northwest" => %w[plm-tools erp-mes conference pacific-northwest engineers managers],
    "Arena PLM Administrator Training – Portland" => %w[plm-tools-arena training pacific-northwest engineers],
    "Pacific NW CAD/CAM & Digital Manufacturing Meetup" => %w[general-plm meetup pacific-northwest engineers],
    "Windchill 15 Upgrade Readiness Workshop" => %w[plm-tools-windchill training pacific-northwest engineers]
  }.freeze

  def up
    CATEGORIZATIONS.each do |event_name, slugs|
      event = Event.find_by(name: event_name)
      unless event
        say "  SKIP: event not found — #{event_name}"
        next
      end

      slugs.each do |slug|
        cat = Category.find_by(slug: slug)
        unless cat
          say "  SKIP: category not found — #{slug}"
          next
        end
        Categorization.find_or_create_by!(categorizable: event, category: cat)
      end

      say "  Tagged: #{event_name} (#{slugs.join(', ')})"
    end
  end

  def down
    CATEGORIZATIONS.each_key do |event_name|
      event = Event.find_by(name: event_name)
      next unless event
      event.categorizations.destroy_all
    end
  end
end
