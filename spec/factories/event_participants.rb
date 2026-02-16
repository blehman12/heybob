FactoryBot.define do
  factory :event_participant do
    role { 'attendee' }
    rsvp_status { 'pending' }
    invited_at { Time.current }
    is_guest { false }
    
    association :user
    association :event

    trait :confirmed do
      rsvp_status { 'yes' }
      responded_at { Time.current }
    end

    trait :declined do
      rsvp_status { 'no' }
      responded_at { Time.current }
    end

    trait :maybe do
      rsvp_status { 'maybe' }
      responded_at { Time.current }
    end

    trait :organizer do
      role { 'organizer' }
      rsvp_status { 'yes' }
    end

    trait :vendor do
      role { 'vendor' }
    end

    trait :checked_in do
      checked_in_at { Time.current }
      check_in_method { 'manual' }
    end

    trait :guest do
      is_guest { true }
      user { nil }
      guest_name { Faker::Name.name }
      guest_email { Faker::Internet.email }
      guest_phone { Faker::PhoneNumber.phone_number }
    end
  end
end
