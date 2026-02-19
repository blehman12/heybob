class FixAdminUserRole < ActiveRecord::Migration[7.1]
  def up
    # User.roles has string keys, not symbol keys
    # User.roles['admin'] returns 1, User.roles[:admin] returns nil (bug!)
    User.where(first_name: 'Admin', last_name: 'User').update_all(role: 1)
  end

  def down
    # no-op
  end
end
