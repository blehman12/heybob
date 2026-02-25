# db/migrate/20260225000002_bootstrap_seed_users.rb
# One-time data migration to create the initial admin + smoketest accounts.
# Safe to re-run — skips if users already exist (checks by email).
class BootstrapSeedUsers < ActiveRecord::Migration[7.1]
  def up
    [
      {
        email:      'admin@nwtg.com',
        first_name: 'Admin',
        last_name:  'User',
        password:   ENV.fetch('BOOTSTRAP_ADMIN_PASSWORD', 'Ch@ngeMe2026!'),
        phone:      '503-555-0001',
        company:    'NWTG',
        role:       1  # super_admin
      },
      {
        email:      'smoketest@heybob.app',
        first_name: 'Smoke',
        last_name:  'Test',
        password:   'Sm0keTest!',
        phone:      '503-555-9999',
        company:    'HeyBob QA',
        role:       1  # super_admin
      }
    ].each do |attrs|
      next if User.exists?(email: attrs[:email])

      user = User.new(attrs.except(:role))
      user.role = attrs[:role]
      if user.save
        puts "  Created #{attrs[:email]} (super_admin)"
      else
        puts "  FAILED #{attrs[:email]}: #{user.errors.full_messages.join(', ')}"
      end
    end
  end

  def down
    # Never delete production users in a rollback
  end
end
