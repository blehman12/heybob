class FixVenuesContactFields < ActiveRecord::Migration[7.1]
  def up
    # Add the contact_info column that the app expects
    add_column :venues, :contact_info, :text unless column_exists?(:venues, :contact_info)

    # Remove legacy columns from original migration if they exist
    remove_column :venues, :amenities      if column_exists?(:venues, :amenities)
    remove_column :venues, :contact_email  if column_exists?(:venues, :contact_email)
    remove_column :venues, :contact_phone  if column_exists?(:venues, :contact_phone)
    
    # Also fix the null constraint on name (original had null: false, schema.rb shows nullable)
    change_column_null :venues, :name, true if column_exists?(:venues, :name)
    
    # Remove the index on name if it exists (not in schema.rb)
    remove_index :venues, :name if index_exists?(:venues, :name)
  end

  def down
    add_column :venues, :amenities,     :text    unless column_exists?(:venues, :amenities)
    add_column :venues, :contact_email, :string  unless column_exists?(:venues, :contact_email)
    add_column :venues, :contact_phone, :string  unless column_exists?(:venues, :contact_phone)
    remove_column :venues, :contact_info if column_exists?(:venues, :contact_info)
  end
end
