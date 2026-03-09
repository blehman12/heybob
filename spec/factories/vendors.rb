FactoryBot.define do
  factory :vendor do
    name { Faker::Company.name }
    participant_type { 'business' }
    description { Faker::Lorem.sentence }
    website { Faker::Internet.url }

    association :user

    trait :artist do
      participant_type { 'artist' }
      name { Faker::Name.name }
    end

    trait :with_social do
      instagram_handle { "@#{Faker::Internet.username}" }
      twitter_handle   { "@#{Faker::Internet.username}" }
    end
  end
end
