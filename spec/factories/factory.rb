# frozen_string_literal: true

DEFAULT_PASSWORD = '321Passwd$$$'

FactoryBot.define do
  factory :user do
    transient do
      num_rosters { rand(0..10) }
    end

    email { Faker::Internet.email }
    password { DEFAULT_PASSWORD }
    confirmed_at { DateTime.now }

    after(:create) do |user, evaluator|
      create_list(:roster,
                  evaluator.num_rosters,
                  user: user)
    end
  end

  sequence(:roster_count) { |n| n }

  factory :roster do
    transient do
      num_participants { rand(5..20) }
      num_participant_properties { rand(0..5) }
    end

    user
    name { "#{user.email}-roster#{generate(:roster_count)}" }
    participant_properties { num_participant_properties.times.collect { |n| "#{n}_#{Faker::Lorem.word}" } }

    after(:create) do |roster, evaluator|
      create_list(:participant, evaluator.num_participants, roster: roster)
    end
  end

  factory :participant do
    first { Faker::Name.first_name }
    last { Faker::Name.last_name }
    roster

    extras do
      roster.participant_properties.to_h do |property|
        [property, Faker::Lorem.word]
      end
    end
  end
end
