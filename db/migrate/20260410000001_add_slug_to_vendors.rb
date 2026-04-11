class AddSlugToVendors < ActiveRecord::Migration[7.1]
  def up
    add_column :vendors, :slug, :string
    add_index :vendors, :slug, unique: true

    # Backfill slugs for existing vendors
    Vendor.find_each do |vendor|
      base = vendor.name.parameterize
      candidate = base
      counter = 2
      while Vendor.where(slug: candidate).where.not(id: vendor.id).exists?
        candidate = "#{base}-#{counter}"
        counter += 1
      end
      vendor.update_column(:slug, candidate)
    end
  end

  def down
    remove_column :vendors, :slug
  end
end
