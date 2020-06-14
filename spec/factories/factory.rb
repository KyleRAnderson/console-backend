# frozen_string_literal: true

DEFAULT_PASSWORD = '321Passwd$$$'

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { DEFAULT_PASSWORD }
    confirmed_at { DateTime.now }

    factory :user_with_rosters do
      transient do
        num_rosters { rand(1..10) }
      end

      after(:create) do |user, evaluator|
        create_list(:roster_with_participants_hunts,
                    evaluator.num_rosters,
                    owner: user)
      end
    end
  end

  factory :permission do
    level { :owner }
    user
    roster
  end

  factory :roster do
    owner factory: :user
    sequence(:name) { |n| "roster#{n}" }
    participant_properties { num_participant_properties.times.map { |n| "#{n}_#{Faker::Lorem.word}" } }

    factory :roster_with_participants_hunts do
      transient do
        num_participants { rand(5..20) }
        num_participant_properties { rand(0..5) }
        num_hunts { rand(1..5) }
      end

      after(:create) do |roster, evaluator|
        create_list(:participant, evaluator.num_participants, roster: roster)
        create_list(:hunt_with_licenses_rounds, evaluator.num_hunts, roster: roster)
      end
    end
  end

  factory :participant do
    first { Faker::Name.first_name }
    last { Faker::Name.last_name }
    roster factory: :roster_with_participants_hunts

    extras do
      roster.participant_properties.to_h do |property|
        [property, Faker::Lorem.word]
      end
    end
  end

  factory :hunt do
    name { Faker::Ancient.god }
    roster factory: :roster_with_participants_hunts

    factory :hunt_with_licenses_rounds do
      transient do
        num_rounds { rand(0..10) }
        generate_licenses { true }
      end

      after(:create) do |hunt, evaluator|
        evaluator.num_rounds.times.map do |i|
          create(:round, hunt: hunt, number: i + 1)
        end
        if evaluator.generate_licenses
          hunt.roster.participants.each do |participant|
            create(:license, participant: participant, hunt: hunt)
          end
        end
      end
    end
  end

  factory :license do
    eliminated { false }
    hunt
    participant { create(:participant, roster: hunt.roster) }
  end

  factory :round do
    hunt
  end

  factory(:match) do
    round
    licenses { create_list(:license, 2) }
  end
end
