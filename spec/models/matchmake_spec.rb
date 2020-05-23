require 'rails_helper'

def check_matches(matches, original_num_licenses)
  expect(matches.count).to eq(original_num_licenses / 2) # Integer division
  expect(matches.save_all).to be true
end

def expect_leftover(matchmake, has_leftover)
  expect(matchmake.leftover.count).to eq(has_leftover ? 1 : 0)
end

def expect_all_licenses_present(matches, licenses)
  license_ids = licenses.map(&:id).uniq
  matches.each do |match|
    # Don't use match.participants.each here because I want to verify 2 licenses per match
    2.times do |i|
      id = match.licenses[i].id
      expect(license_ids).to include(id)
      license_ids.delete(id)
    end
  end
end

# num_overflow: Number of odd licenses in the `within` groupings.
# overflow_properties: The values of the participant extras that
# are expected to be found in overflow matches
# leftover: True if there should be a leftover license, false otherwise
def check_matches_generated_within(matchmake,
                                   original_licenses,
                                   within_properties,
                                   num_overflow: 0,
                                   overflow_properties: [],
                                   leftover: false)
  matches = matchmake.matches
  check_matches(matches, original_licenses.count)
  expect_all_licenses_present(matches, original_licenses)

  split_matches = matches.group_by do |match|
    equal_properties = true
    within_properties.each do |property|
      equal_properties &&=
        match.participants[0].extras[property] == match.participants[1].extras[property]
      break unless equal_properties
    end
    equal_properties
  end

  if num_overflow > 0
    expect(split_matches[false].count).to eq(num_overflow / 2)
    split_matches[false].each do |match|
      (0..1).each do |i|
        overflowed = match.participants[i].extras.map { |_, value| value }
        expect(overflow_properties).to include(*overflowed)
        overflowed.each do |property|
          overflow_properties.delete_at(overflow_properties.index(property))
        end
      end
    end
  end

  expect_leftover(matchmake, leftover)
end

# Generates a key to use to describe a matchup of certain participant properties in a match
# Example: Given match with participant1 properties: ['one': 'value1A', 'two': 'value2A']
# And participant2 properties: ['one': 'value1B', 'two': 'value2B'], the hash would be:
# [['value1A', 'value2A'], ['value1B', 'value2B']]
# This is supposed to act as a unique identifier for a certain matchup between participants
# of different property values.
def generate_match_between_property_hash(match, between_properties)
  match_properties_hash = match.participants.map do |participant|
    property_values = between_properties.map do |property|
      participant.extras[property]
    end
    property_values.sort
  end
  match_properties_hash.sort
end

def check_matches_generated_between(matchmake,
                                    original_licenses,
                                    between_properties,
                                    num_overflow: 0,
                                    overflow_properties: [],
                                    leftover: false)
  matches = matchmake.matches
  check_matches(matches, original_licenses.count)
  expect_all_licenses_present(matches, original_licenses)
  expect_leftover(matchmake, leftover)

  associations = matches.group_by do |match|
    generate_match_between_property_hash(match, between_properties)
  end
end

def generate_participants(roster, number_lists, &block)
  number_lists.times do |i|
    number, *property_values = block.call(i)
    participant_extras = roster.participant_properties.each_with_index.to_h do |property, j|
      [property, property_values[j].to_s]
    end
    create_list(:participant, number, roster: roster, extras: participant_extras)
  end
end

RSpec.fdescribe Matchmake do
  # Custom RSpec matchers

  PROPERTIES = ['num', 'food'].freeze

  # Has to be referenced after roster creation.
  let(:hunt) { create(:hunt_with_licenses_rounds, roster: roster, num_rounds: 1) }
  let(:roster) { create(:roster, participant_properties: participant_properties) }

  describe 'within matchmaking' do
    context 'with a single within property' do
      let(:participant_properties) { PROPERTIES[0..0] }

      context 'with four distinct participant groups' do
        it 'generates a correct match set' do
          generate_participants(roster, 4) { |index| [10, index] }

          matchmake = Matchmake.new(hunt.licenses, within: participant_properties, round_id: hunt.rounds.first.id)
          matches = matchmake.matchmake

          expect(matches).to eq(matchmake.matches)
          check_matches_generated_within(matchmake, hunt.licenses, participant_properties)
        end
      end

      context 'with licenses that will generate overflow' do
        it 'generates matches within and handles overflow between' do
          generate_participants(roster, 4) { |index| [11, index] }

          matchmake = Matchmake.new(hunt.licenses, within: participant_properties, round_id: hunt.rounds.first.id)
          matchmake.matchmake

          check_matches_generated_within(matchmake, hunt.licenses, participant_properties,
                                         num_overflow: 4, overflow_properties: %w[0 1 2 3])
        end
      end
    end

    context 'with multiple `within` properties' do
      let(:participant_properties) { PROPERTIES[0..1] }

      context 'without overflow' do
        it 'generates matches correctly' do
          faker_items = UniqueCollectionGenerator.generate(5) { Faker::Food.dish }
          generate_participants(roster, 5) { |index| [16, index, faker_items[index]] }

          matchmake = Matchmake.new(hunt.licenses, within: participant_properties, round_id: hunt.rounds.first.id)
          matchmake.matchmake

          check_matches_generated_within(matchmake, hunt.licenses, participant_properties)
        end
      end

      context 'with overflow and leftover' do
        it 'generates matches correctly' do
          first_properties = 5.times.map(&:to_s)
          second_properties = UniqueCollectionGenerator.generate(5) { Faker::Food.dish }
          generate_participants(roster, 5) { |index| [17, first_properties[index], second_properties[index]] }

          matchmake = Matchmake.new(hunt.licenses, within: participant_properties, round_id: hunt.rounds.first.id)
          matchmake.matchmake

          check_matches_generated_within(matchmake,
                                         hunt.licenses,
                                         participant_properties,
                                         num_overflow: 4,
                                         overflow_properties: first_properties + second_properties,
                                         leftover: true)
        end
      end

      context 'with overflow on specific properties only' do
        it 'generates matches correctly' do
          first_properties = 4.times.map(&:to_s)
          second_properties = UniqueCollectionGenerator.generate(4) { Faker::Food.dish }

          overflow_properties = first_properties[0..1] + second_properties[0..1]

          generate_participants(roster, 4) do |index|
            # 15 participants for the first two, to have overflow, then an even 16 for the remaining two.
            [(0..1).include?(index) ? 15 : 16, first_properties[index], second_properties[index]]
          end

          matchmake = Matchmake.new(hunt.licenses, within: participant_properties, round_id: hunt.rounds.first.id)
          matchmake.matchmake

          check_matches_generated_within(matchmake,
                                         hunt.licenses,
                                         participant_properties,
                                         num_overflow: 2,
                                         overflow_properties: overflow_properties)
        end
      end
    end
  end

  describe 'between matchmaking' do
    context 'with a single between property' do
      let(:participant_properties) { PROPERTIES[0..0] }

      context 'with no leftover licenses or overflow matches, and even number of groups' do
        it 'generates matches correctly' do
          generate_participants(roster, 4) { |index| [15, index.to_s] }

          matchmake = Matchmake.new(hunt.licenses, between: participant_properties, round_id: hunt.rounds.first.id)
          matchmake.matchmake

          check_matches_generated_between(matchmake,
                                          hunt.licenses,
                                          participant_properties)
        end
      end

      context 'with leftover licenses and overflow matches' do
        it 'generates matches correctly' do
        end
      end
    end
  end
end
