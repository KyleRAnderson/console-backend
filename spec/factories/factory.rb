# frozen_string_literal: true

PASSWORD_CHARS = (('a'..'z').to_a * 2 + ('A'..'Z').to_a * 2 + ('0'..'9').to_a + "!@#$%^&*()_=-".chars).freeze

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { PASSWORD_CHARS.shuffle[0..rand(8..12)].join }
    confirmed_at { DateTime.now }

    trait :with_rosters do
      transient do
        num_rosters { rand(1..10) }
      end

      after(:create) do |user, evaluator|
        create_list(:full_roster, evaluator.num_rosters, user: user)
      end
    end

    factory :user_with_rosters, traits: [:with_rosters]
  end

  factory :permission do
    level { :owner }
    user
    roster { false }

    after(:build) do |permission|
      # == false because don't want to create it if given nil.
      if permission.roster == false
        permission.roster = build(:roster, permissions: [permission])
      end
    end

    factory :administrator do
      level { :administrator }
    end

    factory :operator do
      level { :operator }
    end

    factory :viewer do
      level { :viewer }
    end
  end

  factory :blank_roster, class: Roster do
    sequence(:name) { |n| "roster#{n}" }

    trait :with_participant_properties do
      # Really "possibly_with_participant_properties"
      transient do
        num_participant_properties { rand(0..5) }
      end

      participant_properties do
        num_participant_properties.times.map { |n| "#{n}_#{Faker::Lorem.word}" }
      end
    end

    trait :with_owner do
      transient do
        user { build(:user) }
        owner_permission { nil }
      end

      after(:build) do |roster, evaluator|
        if roster.permissions.select(&:owner?).blank?
          owner_permission = evaluator.owner_permission ||
                             build(:permission, roster: roster, user: evaluator.user)
          roster.permissions << owner_permission
        end
      end
    end

    trait :multiple_permissions do
      transient do
        num_administrators { rand(1..5) }
        num_operators { rand(2..10) }
        num_viewers { rand(1..10) }
      end

      after(:create) do |roster, evaluator|
        create_list(:administrator, evaluator.num_administrators, roster: roster)
        create_list(:operator, evaluator.num_operators, roster: roster)
        create_list(:viewer, evaluator.num_viewers, roster: roster)
      end
    end

    trait :with_hunts do
      transient do
        num_hunts { rand(1..5) }
      end

      after(:create) do |roster, evaluator|
        create_list(:full_hunt, evaluator.num_hunts, roster: roster)
      end
    end

    trait :with_participants do
      transient do
        num_participants { rand(5..20) }
      end

      after(:create) do |roster, evaluator|
        create_list(:participant, evaluator.num_participants, roster: roster)
      end
    end

    factory :roster, traits: %i[with_participant_properties with_owner]
    factory :roster_with_participants, traits: %i[with_participant_properties with_owner with_participants]

    factory :full_roster do
      with_participant_properties # First before participants for participants to get properties
      with_participants # Before hunts so licenses are generated.
      with_owner
      with_hunts
    end
  end

  factory :participant do
    first { Faker::Name.first_name }
    last { Faker::Name.last_name }
    roster factory: :roster

    extras do
      roster.participant_properties.to_h do |property|
        [property, Faker::Lorem.word]
      end
    end
  end

  factory :hunt do
    name { Faker::Ancient.god }
    roster factory: :roster

    trait :with_licenses do
      after(:create) do |hunt|
        hunt.roster.participants.each do |participant|
          create(:license, participant: participant, hunt: hunt)
        end
      end
    end

    trait :with_rounds do
      transient do
        num_rounds { rand(1..10) }
      end

      after(:create) do |hunt, evaluator|
        evaluator.num_rounds.times.map do |i|
          create(:round, hunt: hunt, number: i + 1)
        end
      end
    end

    factory :hunt_with_licenses, traits: [:with_licenses]
    factory :hunt_with_rounds, traits: [:with_rounds]
    factory :full_hunt, traits: %i[with_licenses with_rounds]
  end

  factory :license do
    eliminated { false }
    hunt
    # Need block for this participant because otherwise hunt isn't available.
    participant { create(:participant, roster: hunt.roster) }
  end

  factory :round do
    hunt
  end

  factory :match do
    round
    licenses { create_list(:license, 2, hunt: round.hunt) }
  end
end
