FactoryBot.define do
  factory :con_opt_in do
    name  { Faker::Name.name }
    phone { Faker::PhoneNumber.cell_phone_in_e164 }
    email { nil }
    # opted_in_at is auto-set by before_validation callback

    association :event
    association :vendor_event

    trait :email_only do
      phone { nil }
      email { Faker::Internet.email }
    end

    trait :both_contacts do
      phone { Faker::PhoneNumber.cell_phone_in_e164 }
      email { Faker::Internet.email }
    end

    trait :with_user do
      association :user
    end
  end
end
