# ── Taxonomy seed ──────────────────────────────────────────────────────────────
puts "Seeding categories..."

taxonomy = {
  domain: [
    { name: 'PLM Tools', children: ['Windchill', 'Creo', 'Arena', 'Teamcenter', 'ENOVIA'] },
    { name: 'ERP / MES', children: ['SAP', 'Oracle'] },
    { name: 'General PLM', children: [] }
  ],
  format: [
    { name: 'Conference', children: [] },
    { name: 'User Group', children: [] },
    { name: 'Training',   children: [] },
    { name: 'Meetup',     children: [] },
    { name: 'Trade Show', children: [] },
    { name: 'Convention', children: [] },
    { name: 'Webinar',    children: [] }
  ],
  geography: [
    { name: 'Pacific Northwest', children: [] },
    { name: 'North America',     children: [] },
    { name: 'Europe',            children: [] },
    { name: 'Virtual',           children: [] },
    { name: 'International',     children: [] }
  ],
  fandom: [
    { name: 'Anime',       children: [] },
    { name: 'Gaming',      children: [] },
    { name: 'Comic',       children: [] },
    { name: 'Pop Culture', children: [] },
    { name: 'Tabletop',    children: [] }
  ],
  audience: [
    { name: 'Engineers',  children: [] },
    { name: 'Managers',   children: [] },
    { name: 'IT',         children: [] },
    { name: 'Executives', children: [] },
    { name: 'Other',      children: [] }
  ]
}

taxonomy.each do |facet, entries|
  entries.each_with_index do |entry, pos|
    parent = Category.find_or_create_by!(slug: entry[:name].parameterize) do |c|
      c.name     = entry[:name]
      c.facet    = facet
      c.position = pos
      c.active   = true
    end

    entry[:children].each_with_index do |child_name, child_pos|
      slug = "#{parent.slug}-#{child_name.parameterize}"
      Category.find_or_create_by!(slug: slug) do |c|
        c.name     = child_name
        c.facet    = facet
        c.parent   = parent
        c.position = child_pos
        c.active   = true
      end
    end
  end
end

puts "  Categories: #{Category.count}"
