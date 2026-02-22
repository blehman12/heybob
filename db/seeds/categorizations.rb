# ── Categorization seed ────────────────────────────────────────────────────────
# Assigns categories to existing seed events for dev/test purposes.
# Safe to re-run — uses find_or_create_by on the join table.
#
# Assumes:
#   - categories have been seeded (run db/seeds/categories.rb first)
#   - at least the 3 standard dev events exist
# ────────────────────────────────────────────────────────────────────────────────

puts "Seeding categorizations..."

# Helper: find category by slug, warn if missing
def cat(slug)
  Category.find_by(slug: slug).tap do |c|
    puts "  ⚠ Category not found: #{slug}" unless c
  end
end

# Helper: assign category to a record, idempotent
def tag(record, category)
  return unless record && category
  Categorization.find_or_create_by!(
    categorizable: record,
    category: category
  )
end

# ── Event: PTC Windchill Community Meetup ──────────────────────────────────────
windchill_meetup = Event.find_by("name LIKE ?", "%Windchill Community Meetup%")

if windchill_meetup
  tag(windchill_meetup, cat('plm-tools'))          # domain > PLM Tools
  tag(windchill_meetup, cat('plm-tools-windchill')) # domain > Windchill
  tag(windchill_meetup, cat('meetup'))              # format > Meetup
  tag(windchill_meetup, cat('pacific-northwest'))   # geography > Pacific Northwest
  tag(windchill_meetup, cat('engineers'))           # audience > Engineers
  tag(windchill_meetup, cat('managers'))            # audience > Managers
  puts "  Tagged: #{windchill_meetup.name}"
else
  puts "  ⚠ Event not found: Windchill Community Meetup"
end

# ── Event: PTC Windchill Advanced Training Workshop ───────────────────────────
training = Event.find_by("name LIKE ?", "%Training Workshop%")

if training
  tag(training, cat('plm-tools'))
  tag(training, cat('plm-tools-windchill'))
  tag(training, cat('training'))                   # format > Training
  tag(training, cat('north-america'))              # geography > North America
  tag(training, cat('engineers'))
  tag(training, cat('it'))                         # audience > IT
  puts "  Tagged: #{training.name}"
else
  puts "  ⚠ Event not found: Training Workshop"
end

# ── Event: PTC Windchill Summer Networking ────────────────────────────────────
networking = Event.find_by("name LIKE ?", "%Summer Networking%")

if networking
  tag(networking, cat('plm-tools'))
  tag(networking, cat('plm-tools-windchill'))
  tag(networking, cat('user-group'))               # format > User Group
  tag(networking, cat('pacific-northwest'))
  tag(networking, cat('engineers'))
  tag(networking, cat('managers'))
  tag(networking, cat('executives'))
  puts "  Tagged: #{networking.name}"
else
  puts "  ⚠ Event not found: Summer Networking"
end

# ── Sakuracon placeholder (if it exists yet) ──────────────────────────────────
sakuracon = Event.find_by("name LIKE ?", "%Sakura%")

if sakuracon
  tag(sakuracon, cat('anime'))                     # fandom > Anime
  tag(sakuracon, cat('pop-culture'))               # fandom > Pop Culture
  tag(sakuracon, cat('convention'))                # format > Convention
  tag(sakuracon, cat('pacific-northwest'))
  puts "  Tagged: #{sakuracon.name}"
end

puts "  Categorizations: #{Categorization.count}"
