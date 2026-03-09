FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { 'attendee' }
    company { Faker::Company.name }
    phone { Faker::PhoneNumber.phone_number }

    trait :admin do
      role { 'super_admin' }
    end

    trait :super_admin do
      role { 'super_admin' }
    end

    trait :event_admin do
      role { 'event_admin' }
    end

    trait :vendor_admin do
      role { 'vendor_admin' }
    end
  end
end
