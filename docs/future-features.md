# Future Features & Architecture Decisions

## Multi-Tenant Organization Model
*Saved: 2025-10-01*
*Status: Future consideration - Phase 2/3*

### Context
Currently, confab operates as a single-tenant application where admin users manage all events for one organization ( Windchill community). DICE.fm's model inspired thinking about eventually allowing multiple independent promoters/organizations to self-manage their own events through the platform.

### What DICE Does
- Multiple independent promoters manage their own events
- `promoter_name` field (e.g., "Presented by Minty Boi") indicates who runs each event
- Platform provides infrastructure, promoters own content
- Self-service event and venue management

### Proposed Architecture

#### 1. New Organization Model
```ruby
# New table: organizations
create_table :organizations do |t|
  t.string :name              # "Minty Boi", "Portland Chapter"
  t.text :description
  t.string :contact_email
  t.integer :owner_id         # User who created organization
  t.timestamps
end

# Junction table: organization_memberships
create_table :organization_memberships do |t|
  t.integer :user_id
  t.integer :organization_id
  t.string :role              # owner, manager, staff
  t.timestamps
end

# Add to events table
t.integer :organization_id   # Who's running this event
t.boolean :public_listing, default: true  # Show in public directory?
