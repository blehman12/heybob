class CreateInitialAdminUser < ActiveRecord::Migration[7.1]
  def up
    # Skip if the user already exists
    return if User.exists?(email: "admin@example.com")

    User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      admin: true
    )
  end

  def down
    user = User.find_by(email: "admin@example.com")
    user&.destroy
  end
end
