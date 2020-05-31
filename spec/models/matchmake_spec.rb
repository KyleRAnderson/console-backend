require 'rails_helper'

=begin
Side note: I could have made several of these into their own
custom matchers, but it would be ugly and have less
messaging for which aspect failed.
=end

def check_matches(matchmake,
                  original_licenses,
                  within_properties: [],
                  between_properties: [],
                  num_within_overflow: 0,
                  within_overflow_properties: [],
                  leftover: false,
                  &between_validator)
  matches = matchmake.matches
  check_match_basics(matches, original_licenses.count)
  check_all_licenses_present(matches, original_licenses)

  unless within_properties.empty?
    check_valid_within_matches(matches, within_properties,
                               num_overflow: num_within_overflow,
                               overflow_properties: within_overflow_properties)
  end

  unless between_properties.empty?
    check_valid_between_matches(matches, between_properties, &between_validator)
  end

  check_leftover(matchmake, leftover)
end

def check_match_basics(matches, original_num_licenses)
  expect(matches.count).to eq(original_num_licenses / 2) # Integer division
  expect(matches.save_all).to be true
  matches.each { |match| expect(match.participants.count).to eq(2) }
end

def check_leftover(matchmake, has_leftover)
  expect(matchmake.leftover.count).to eq(has_leftover ? 1 : 0)
end

def check_all_licenses_present(matches, licenses)
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
def check_valid_within_matches(matches,
                               within_properties,
                               num_overflow: 0,
                               overflow_properties: [])
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
end

def check_valid_between_matches(matches, between_properties, &validator)
  associations = matches.group_by do |match|
    generate_property_digest(match, between_properties)
  end
  associations = associations.to_h { |value_digest, matches_group| [value_digest, matches_group.length] }
  validator&.call(associations)
end

# Generates a key to use to describe a matchup of certain participant properties in a match
# Example: Given match with participant1 properties: ['one': 'value1A', 'two': 'value2A']
# And participant2 properties: ['one': 'value1B', 'two': 'value2B'], the hash would be:
# [['value1A', 'value2A'], ['value1B', 'value2B']]
# This is supposed to act as a unique identifier for a certain matchup between participants
# of different property values.
def generate_property_digest(match, between_properties)
  match_properties_hash = match.participants.map do |participant|
    property_values = between_properties.map do |property|
      participant.extras[property]
    end
    property_values.sort
  end
  match_properties_hash.sort
end

def generate_participants(roster, number_lists, &block)
  number_lists.times do |i|
    number, participant_extras = block.call(i)
    participant_extras = {} unless participant_extras
    create_list(:participant, number, roster: roster, extras: participant_extras)
  end
end

RSpec.describe Matchmake do
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
          generate_participants(roster, 4) { |index| [10, { participant_properties[0] => index.to_s }] }

          matchmake = Matchmake.new(hunt.licenses, within: participant_properties, round_id: hunt.rounds.first.id)
          matches = matchmake.matchmake

          expect(matches).to eq(matchmake.matches)
          check_matches(matchmake, hunt.licenses, within_properties: participant_properties)
        end
      end

      context 'with licenses that will generate overflow' do
        it 'generates matches within and handles overflow between' do
          generate_participants(roster, 4) { |index| [11, { participant_properties[0] => index.to_s }] }

          matchmake = Matchmake.new(hunt.licenses, within: participant_properties, round_id: hunt.rounds.first.id)
          matchmake.matchmake

          check_matches(matchmake, hunt.licenses, within_properties: participant_properties,
                                                  num_within_overflow: 4, within_overflow_properties: %w[0 1 2 3])
        end
      end
    end

    context 'with multiple `within` properties' do
      let(:participant_properties) { PROPERTIES[0..1] }

      context 'without overflow' do
        it 'generates matches correctly' do
          faker_items = UniqueCollectionGenerator.generate(5) { Faker::Food.dish }
          generate_participants(roster, 5) { |index|
            [16,
             { participant_properties[0] => index.to_s, participant_properties[1] => faker_items[index] }]
          }

          matchmake = Matchmake.new(hunt.licenses, within: participant_properties, round_id: hunt.rounds.first.id)
          matchmake.matchmake

          check_matches(matchmake, hunt.licenses, within_properties: participant_properties)
        end
      end

      context 'with overflow and leftover' do
        it 'generates matches correctly' do
          first_properties = 5.times.map(&:to_s)
          second_properties = UniqueCollectionGenerator.generate(5) { Faker::Food.dish }
          generate_participants(roster, 5) do |index|
            [17,
             { participant_properties[0] => first_properties[index],
              participant_properties[1] => second_properties[index] }]
          end

          matchmake = Matchmake.new(hunt.licenses, within: participant_properties, round_id: hunt.rounds.first.id)
          matchmake.matchmake

          check_matches(matchmake,
                        hunt.licenses,
                        within_properties: participant_properties,
                        num_within_overflow: 4,
                        within_overflow_properties: first_properties + second_properties,
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
            [(0..1).include?(index) ? 15 : 16,
             { participant_properties[0] => first_properties[index], participant_properties[1] => second_properties[index] }]
          end

          matchmake = Matchmake.new(hunt.licenses, within: participant_properties, round_id: hunt.rounds.first.id)
          matchmake.matchmake

          check_matches(matchmake,
                        hunt.licenses,
                        within_properties: participant_properties,
                        num_within_overflow: 2,
                        within_overflow_properties: overflow_properties)
        end
      end
    end
  end

  describe 'between matchmaking' do
    context 'with a single between property' do
      let(:participant_properties) { PROPERTIES[0..0] }

      context 'with one-to-one matchable groups,' do
        it 'generates matches with no leftover or overflow' do
          property_values = (0..3).map(&:to_s)
          generate_participants(roster, 4) { |index| [15, { participant_properties[0] => property_values[index] }] }

          matchmake = Matchmake.new(hunt.licenses, between: participant_properties, round_id: hunt.rounds.first.id)
          matchmake.matchmake

          check_matches(matchmake,
                        hunt.licenses,
                        between_properties: participant_properties) do |associations|
            expect(associations.length).to eq(2)
            associations.each do |association, match_count|
              expect(match_count).to eq(15)
              association.each do |association_value|
                expect(property_values.count(association_value[0])).to eq(1)
                associations.delete(association_value[0])
              end
            end
          end
        end
      end

      context 'with an odd number of licenses and unmatched between groups' do
        it 'generates matches with a leftover license and between overflow' do
          first_property_values = (0..2).map(&:to_s)
          generate_participants(roster, 3) { |index| [6 + index, { participant_properties[0] => first_property_values[index].to_s }] }

          matchmake = Matchmake.new(hunt.licenses, between: participant_properties, round_id: hunt.rounds.first.id)
          matchmake.matchmake

          check_matches(matchmake,
                        hunt.licenses,
                        between_properties: participant_properties,
                        leftover: true) do |associations|
            expect(associations.length).to eq(3)
            expect(associations).to satisfy do |a|
              a == { [%w[0], %w[1]] => 6, [%w[1], %w[2]] => 1, [%w[2], %w[2]] => 3 } ||
                a == { [%w[0], %w[2]] => 6, [%w[1], %w[2]] => 2, [%w[1], %w[1]] => 2 } ||
                a == { [%w[1], %w[2]] => 7, [%w[0], %w[2]] => 1, [%w[0], %w[0]] => 2 }
            end
          end
        end
      end
    end
  end

  describe 'within and between matchmaking' do
    let(:within_properties) { ['within'] }
    let(:between_properties) { ['between'] }
    let(:participant_properties) { within_properties + between_properties }

    it 'works on a basic level' do
      unique_values = UniqueCollectionGenerator.generate(20) { Faker::Device.platform }
      within_values = unique_values[0..3]
      between_values = unique_values[4...20]
      generate_participants(roster, 16) do |index|
        [15, { within_properties[0] => within_values[index % 4],
              between_properties[0] => between_values[index] }]
      end

      matchmake = Matchmake.new(hunt.licenses,
                                within: within_properties,
                                between: between_properties,
                                round_id: hunt.rounds.first.id)
      matchmake.matchmake

      check_matches(matchmake,
                    hunt.licenses,
                    within_properties: within_properties,
                    between_properties: between_properties)
    end
  end

  describe 'neither within or between matchmaking' do
    let(:participant_properties) { [] }

    it 'performs within matchmaking on the given licenses' do
      generate_participants(roster, 4) { [10] }

      matchmake = Matchmake.new(hunt.licenses, round_id: hunt.rounds.first.id)
      matchmake.matchmake

      check_matches(matchmake, hunt.licenses)
    end

    context 'with a single license' do
      it 'builds no matches and has one leftover' do
        generate_participants(roster, 1) { [1] }

        matchmake = Matchmake.new(hunt.licenses, round_id: hunt.rounds.first.id)
        matchmake.matchmake

        expect(matchmake.matches).to be_empty
        expect(matchmake.leftover).to contain_exactly(hunt.licenses.first)
      end
    end
  end

  describe 'edege cases' do
    let(:participant_properties) { PROPERTIES[0..0] }

    context 'with intersecting properties for within and between' do
      it 'raises an exception' do
        generate_participants(roster, 4) { |index| [10, { participant_properties[0] => index.to_s }] }
        within_properties = participant_properties.clone
        between_properties = participant_properties.clone

        expect {
          Matchmake.new(hunt.licenses, within: within_properties,
                                       between: between_properties,
                                       round_id: hunt.rounds.first.id)
        }.to(
          raise_exception(Matchmake::COMMON_PROPERTIES_ERROR_MESSAGE)
        )
      end
    end
  end
end
