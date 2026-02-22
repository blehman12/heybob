class CreateInitialAdminUser < ActiveRecord::Migration[7.1]
  def up
    # Skip if an admin user already exists
    return if User.exists?(email: "admin@nwtg.com")

    User.create!(
      email: "admin@nwtg.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Admin",
      last_name: "User",
      phone: "503-555-0100",
      company: "NWTG",
      role: 1  # 1 = super_admin (was 'admin' before role expansion)
    )
  end

  def down
    user = User.find_by(email: "admin@nwtg.com")
    user&.destroy
  end
end
