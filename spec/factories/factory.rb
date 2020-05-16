# frozen_string_literal: true

DEFAULT_PASSWORD = '321Passwd$$$'

FactoryBot.define do
  factory :user do
    transient do
      num_rosters { rand(1..10) }
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

  factory :roster do
    transient do
      num_participants { rand(5..20) }
      num_participant_properties { rand(0..5) }
      num_hunts { rand(1..5) }
    end

    user
    sequence(:name) { |n| "#{user.email}-roster#{n}" }
    participant_properties { num_participant_properties.times.collect { |n| "#{n}_#{Faker::Lorem.word}" } }

    after(:create) do |roster, evaluator|
      create_list(:participant, evaluator.num_participants, roster: roster)
      create_list(:hunt, evaluator.num_hunts, roster: roster)
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

  factory :hunt do
    transient do
      num_rounds { rand(0..10) }
    end

    name { Faker::Ancient.god }
    roster

    after(:create) do |hunt, evaluator|
      evaluator.num_rounds.times.collect do |i|
        create(:round, hunt: hunt, number: i + 1)
      end
    end
  end

  factory :license do
    eliminated { false }
    hunt
    participant
  end

  factory :round do
    sequence(:number, 1) { |n| n }
    hunt
  end
end
