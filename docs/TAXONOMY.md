# evm1 Taxonomy Reference

**Last updated:** February 2026  
**Status:** Active — 5 facets, 32 categories seeded

---

## What is the taxonomy?

A five-facet category system for tagging events (and eventually vendors and users) with structured, meaningful labels. Tags drive public discovery, URL-based filtering, and future interest-based recommendations.

Each event can have any number of tags from any combination of facets. You don't need to use all five — pick what's meaningful for the event.

---

## The Five Facets

| Facet | Question it answers | Example tags |
|-------|---------------------|--------------|
| **domain** | What is it about? | Windchill, Creo, SAP, General PLM |
| **format** | What kind of event? | Conference, Meetup, Convention, Webinar |
| **geography** | Where? | Pacific Northwest, Virtual, International |
| **fandom** | What community? | Anime, Gaming, Comic, Tabletop |
| **audience** | Who is it for? | Engineers, Managers, IT, Executives |

---

## Full Hierarchy

Only **domain** has parent/child structure. All other facets are flat.  
Maximum nesting depth is **one level** — children cannot have children.

```
domain
  └── PLM Tools
        ├── Windchill
        ├── Creo
        ├── Arena
        ├── Teamcenter
        └── ENOVIA
  └── ERP / MES
        ├── SAP
        └── Oracle
  └── General PLM

format (flat)
  Conference · User Group · Training · Meetup · Trade Show · Convention · Webinar

geography (flat)
  Pacific Northwest · North America · Europe · Virtual · International

fandom (flat)
  Anime · Gaming · Comic · Pop Culture · Tabletop

audience (flat)
  Engineers · Managers · IT · Executives · Other
```

---

## Data Model

### Category

| Column | Type | Notes |
|--------|------|-------|
| `name` | string | Display label |
| `slug` | string | URL-safe, auto-generated, unique |
| `facet` | enum | domain / format / geography / fandom / audience |
| `parent_id` | integer | nil for root nodes |
| `position` | integer | Sort order within facet |
| `active` | boolean | Soft-disable without deleting |

Slug generation rules:
- Root: `name.parameterize` → `"PLM Tools"` → `plm-tools`
- Child: `"#{parent.slug}-#{name.parameterize}"` → `plm-tools-windchill`

### Categorization (polymorphic join)

| Column | Type | Notes |
|--------|------|-------|
| `category_id` | integer | FK to Category |
| `categorizable_type` | string | "Event", "Vendor", or "User" |
| `categorizable_id` | integer | FK to the tagged record |

Same table tags events, vendors, and users. Unique index on `(category_id, categorizable_type, categorizable_id)` prevents duplicates.

---

## Rules & Constraints

- A category belongs to exactly one facet
- Parent and child must share the same facet
- Maximum depth is one level (no grandchildren)
- An event can have categories from any/all facets
- Deactivating a category hides it from the admin form but preserves existing associations
- The event form includes a hidden empty `category_ids[]` field so that unchecking all categories correctly clears them on save

---

## Tagging Examples

**Columbia River PLM User Group** — local Windchill meetup for engineers in Portland
```
domain:    Windchill
format:    User Group
geography: Pacific Northwest
audience:  Engineers
```

**Sakuracon 2026** — anime convention in Seattle
```
fandom:    Anime, Pop Culture
format:    Convention
geography: Pacific Northwest
```

**PTC LiveWorx** — annual PTC conference, multi-tool, multi-audience
```
domain:    Windchill, Creo, PLM Tools
format:    Conference
geography: North America
audience:  Engineers, Managers
```

**Windchill Admin Webinar** — online training, IT-focused
```
domain:    Windchill
format:    Webinar
geography: Virtual
audience:  IT
```

---

## Parent vs Child Tagging

Tag at the most specific level that's meaningful:

- Event covers **all PLM tools** → tag `PLM Tools` (parent)
- Event is **specifically Windchill** → tag `Windchill` (child only, skip the parent)
- Event covers **Windchill and Creo** → tag both children, skip the parent

> The public filtering system (not yet built) will need to handle parent/child rollup so that filtering by `PLM Tools` also returns events tagged with `Windchill`, `Creo`, etc.

---

## Code Reference

```ruby
# All active categories for a facet
Category.active.for_facet(:domain).ordered

# Grouped for select dropdowns (used in admin form)
Category.grouped_for_select
# → { "domain" => [["PLM Tools", 1], ["Windchill", 2], ...], ... }

# Categories on an event (efficient — avoids N+1)
event.categories.includes(:parent).order(:facet, :name)

# Events tagged with a specific category slug
cat = Category.find_by(slug: 'windchill')
Event.joins(:categorizations).where(categorizations: { category: cat })

# Check if event has any categories
event.categories.any?
```

---

## URL Filtering (planned — sprint item 4)

```
/events?tag=windchill
/events?tag=windchill&format=user-group
/events?tag=pacific-northwest
/events?domain=windchill&format=meetup    ← Columbia River PLM embed URL
```

The `tag` param will match category slugs. Parent/child rollup behavior TBD.

---

## Admin Operations

### Seed categories (run once after fresh deploy)
```bash
rails runner db/seeds/categories.rb
```

### Seed example categorizations (optional — tags existing events)
```bash
rails runner db/seeds/categorizations.rb
```

### Add a new category via console
```ruby
Category.create!(
  name: 'SolidWorks',
  facet: :domain,
  parent: Category.find_by(slug: 'plm-tools'),
  active: true
)
```

### Deactivate a category (hides from form, keeps existing tags)
```ruby
Category.find_by(slug: 'oracle').update!(active: false)
```

---

## Roadmap

| Item | Status |
|------|--------|
| Category checkboxes on admin event form | ✅ Done |
| Category tags on public event page | ✅ Done |
| Public /events index with filter links | 📋 Next |
| Clean URL filtering (/events?tag=windchill) | 📋 Next |
| Parent/child rollup in filtering | 📋 TBD |
| Category assignment to vendors | 📋 Phase 2 |
| User interest self-selection from taxonomy | 💡 Phase 3 |
| AI-assisted interest inference | 💡 Phase 4 |
