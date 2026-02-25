# db/seeds/smoketest_user.rb
# Creates (or resets) the smoke test account.
# Safe to re-run — uses find_or_create_by on email.
#
# Usage: rails runner db/seeds/smoketest_user.rb

user = User.find_or_initialize_by(email: 'smoketest@heybob.app')
user.first_name = 'Smoke'
user.last_name  = 'Test'
user.password   = 'Sm0keTest!'
user.phone      = '503-555-9999'
user.company    = 'HeyBob QA'
user.role       = :super_admin
user.save!

puts "smoketest@heybob.app — #{user.previously_new_record? ? 'created' : 'updated'} (role: #{user.role})"
