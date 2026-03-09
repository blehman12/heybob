FactoryBot.define do
  factory :broadcast do
    message { Faker::Lorem.sentence(word_count: 10) }
    channel { 'sms' }
    scope   { 'booth_visitors' }

    association :vendor_event

    trait :sent do
      sent_at { 1.hour.ago }
    end

    trait :pending do
      sent_at { nil }
    end

    trait :entire_con do
      scope { 'entire_con' }
    end

    trait :long_message do
      message { 'A' * 160 }
    end
  end
end
