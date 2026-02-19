class FixAdminUserRole < ActiveRecord::Migration[7.1]
  def up
    # Fix any user named 'Admin User' that got created with the wrong role
    User.where(first_name: 'Admin', last_name: 'User').update_all(role: User.roles[:admin])
  end

  def down
    # no-op
  end
end
