class SeedPortlandSeattleDemoData < ActiveRecord::Migration[7.1]
  def up
    admin = User.find_by(email: 'admin@nwtg.com')
    unless admin
      say "admin@nwtg.com not found — skipping demo seed"
      return
    end

    venues = [
      { name: "Oregon Convention Center", address: "777 NE Martin Luther King Jr Blvd, Portland, OR 97232", capacity: 5000, description: "Oregon's largest convention facility, located in the Lloyd District of Portland.", contact_info: "info@oregoncc.org | 503-235-7575" },
      { name: "Hotel Lucia", address: "400 SW Broadway, Portland, OR 97205", capacity: 200, description: "Boutique hotel in downtown Portland with intimate meeting spaces.", contact_info: "events@hotellucia.com | 503-225-1717" },
      { name: "Portland State University – Smith Memorial Student Union", address: "1825 SW Broadway, Portland, OR 97201", capacity: 500, description: "Central campus venue with multiple meeting rooms and auditorium space.", contact_info: "smsu@pdx.edu | 503-725-4451" },
      { name: "Hyatt Regency Seattle", address: "808 Howell St, Seattle, WA 98101", capacity: 800, description: "Modern hotel in downtown Seattle with full conference facilities.", contact_info: "seattle.regency@hyatt.com | 206-973-1234" },
      { name: "Bell Harbor International Conference Center", address: "2211 Alaskan Way, Seattle, WA 98121", capacity: 1200, description: "Waterfront conference center on Pier 66 with panoramic Puget Sound views.", contact_info: "events@bellharbor.com | 206-441-6666" },
      { name: "University of Washington – Kane Hall", address: "4069 Spokane Ln, Seattle, WA 98195", capacity: 700, description: "Major lecture and event venue on the UW Seattle campus.", contact_info: "uwhfs@uw.edu | 206-543-6000" }
    ]

    created_venues = {}
    venues.each do |v|
      venue = Venue.find_or_initialize_by(name: v[:name])
      venue.assign_attributes(v)
      venue.save!
      created_venues[v[:name]] = venue
      say "  Venue: #{venue.name}"
    end

    occ   = created_venues["Oregon Convention Center"]
    lucia = created_venues["Hotel Lucia"]
    psu   = created_venues["Portland State University – Smith Memorial Student Union"]
    hyatt = created_venues["Hyatt Regency Seattle"]
    bell  = created_venues["Bell Harbor International Conference Center"]
    uw    = created_venues["University of Washington – Kane Hall"]

    events = [
      { name: "Pacific Northwest PLM Summit 2025", description: "Annual gathering of PLM practitioners across the Pacific Northwest. Sessions on Windchill, Creo, and digital thread strategy. Keynotes from PTC and local manufacturing leaders.", event_date: Time.zone.parse("2025-10-14 09:00:00"), rsvp_deadline: Time.zone.parse("2025-10-07 23:59:00"), max_attendees: 350, event_type: :hosted, lifecycle_status: :archived, public_rsvp_enabled: false, venue: occ, creator: admin },
      { name: "Windchill User Group – Portland Chapter", description: "Monthly meetup for Windchill administrators and power users in the Portland metro area. Topics this quarter: workspace management best practices, Active Workspace customization, and upgrade planning for Windchill 14.", event_date: Time.zone.parse("2026-03-18 17:30:00"), rsvp_deadline: Time.zone.parse("2026-03-16 23:59:00"), max_attendees: 60, event_type: :hosted, lifecycle_status: :published, public_rsvp_enabled: true, venue: lucia, creator: admin },
      { name: "Creo Power Users Workshop – Seattle", description: "Hands-on full-day workshop for Creo Parametric users. Topics: advanced surfacing, GD&T annotation, simulation-driven design, and Creo+ cloud collaboration features.", event_date: Time.zone.parse("2026-04-08 08:30:00"), rsvp_deadline: Time.zone.parse("2026-04-01 23:59:00"), max_attendees: 80, event_type: :hosted, lifecycle_status: :published, public_rsvp_enabled: true, venue: hyatt, creator: admin },
      { name: "PTC LiveWorx 2026 – Seattle Preview Night", description: "Pre-conference meetup for Pacific Northwest attendees heading to PTC LiveWorx in Boston. Connect with regional peers, preview the agenda, and coordinate travel.", event_date: Time.zone.parse("2026-05-05 18:00:00"), rsvp_deadline: Time.zone.parse("2026-05-03 23:59:00"), max_attendees: 45, event_type: :hosted, lifecycle_status: :published, public_rsvp_enabled: true, venue: bell, creator: admin },
      { name: "ERP & PLM Integration Forum – Pacific Northwest", description: "Cross-functional forum exploring the intersection of ERP (SAP, Oracle) and PLM (Windchill, Teamcenter) systems. Case studies from Boeing, Daimler Truck, and local manufacturers.", event_date: Time.zone.parse("2026-06-11 09:00:00"), rsvp_deadline: Time.zone.parse("2026-06-04 23:59:00"), max_attendees: 150, event_type: :hosted, lifecycle_status: :published, public_rsvp_enabled: true, venue: occ, creator: admin },
      { name: "Arena PLM Administrator Training – Portland", description: "Full-day training for Arena PLM admins. Topics: BOM management, change control workflows, supplier collaboration portal setup, and API integrations.", event_date: Time.zone.parse("2026-07-22 09:00:00"), rsvp_deadline: Time.zone.parse("2026-07-15 23:59:00"), max_attendees: 30, event_type: :hosted, lifecycle_status: :draft, public_rsvp_enabled: false, venue: psu, creator: admin },
      { name: "Pacific NW CAD/CAM & Digital Manufacturing Meetup", description: "Informal evening meetup for engineers and designers working in CAD/CAM, CNC, additive manufacturing, and digital twin technologies. Lightning talks + open networking.", event_date: Time.zone.parse("2026-08-19 17:00:00"), rsvp_deadline: Time.zone.parse("2026-08-17 23:59:00"), max_attendees: 100, event_type: :hosted, lifecycle_status: :published, public_rsvp_enabled: true, venue: uw, creator: admin },
      { name: "Windchill 15 Upgrade Readiness Workshop", description: "Half-day technical workshop covering what's new in Windchill 15, upgrade path considerations, and lessons learned from early adopters. Q&A with PTC solution engineers.", event_date: Time.zone.parse("2026-09-10 13:00:00"), rsvp_deadline: Time.zone.parse("2026-09-05 23:59:00"), max_attendees: 50, event_type: :hosted, lifecycle_status: :draft, public_rsvp_enabled: false, venue: hyatt, creator: admin }
    ]

    events.each do |e|
      event = Event.find_or_initialize_by(name: e[:name])
      event.assign_attributes(e)
      event.save!
      say "  Event: #{event.name} [#{event.lifecycle_status}]"
    end
  end

  def down
    Event.where(name: [
      "Pacific Northwest PLM Summit 2025",
      "Windchill User Group – Portland Chapter",
      "Creo Power Users Workshop – Seattle",
      "PTC LiveWorx 2026 – Seattle Preview Night",
      "ERP & PLM Integration Forum – Pacific Northwest",
      "Arena PLM Administrator Training – Portland",
      "Pacific NW CAD/CAM & Digital Manufacturing Meetup",
      "Windchill 15 Upgrade Readiness Workshop"
    ]).destroy_all

    Venue.where(name: [
      "Oregon Convention Center",
      "Hotel Lucia",
      "Portland State University – Smith Memorial Student Union",
      "Hyatt Regency Seattle",
      "Bell Harbor International Conference Center",
      "University of Washington – Kane Hall"
    ]).destroy_all
  end
end
