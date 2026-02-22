class AddTaxonomyAndRoles < ActiveRecord::Migration[7.1]
  def change
    # ── Categories ──────────────────────────────────────────────
    create_table :categories do |t|
      t.string  :name,        null: false
      t.string  :slug,        null: false
      t.integer :facet,       null: false, default: 0
      t.integer :parent_id                          # one level of hierarchy
      t.string  :description
      t.integer :position,    default: 0            # for ordering within facet
      t.boolean :active,      default: true
      t.timestamps
    end
    add_index :categories, :slug,      unique: true
    add_index :categories, :facet
    add_index :categories, :parent_id

    # ── Categorizations (polymorphic join) ───────────────────────
    create_table :categorizations do |t|
      t.references :category,      null: false, foreign_key: true
      t.references :categorizable,  null: false, polymorphic: true
      t.timestamps
    end
    add_index :categorizations, [:category_id, :categorizable_type, :categorizable_id],
              unique: true, name: 'idx_categorizations_unique'

    # ── Expand user roles ────────────────────────────────────────
    # Existing values:  attendee: 0, admin: 1
    # New values keep 1 → super_admin so existing admins are preserved
    # attendee: 0, super_admin: 1, event_admin: 2, venue_admin: 3, vendor_admin: 4

    # ── User interests ───────────────────────────────────────────
    # Users get categorizations via the polymorphic join above.
    # No schema change needed — User is just another categorizable type.
  end
end
