# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Roster, type: :model do
  let(:user) { create(:user) }

  it 'deletes associated participants upon destroy' do
    roster = create(:full_roster, user: user, num_participants: 100)
    roster.destroy!

    expect(Roster.count).to eq(0)
    expect(Participant.count).to eq(0)
  end

  describe 'before validation' do
    it 'strips participant properties' do
      [' no good', ' also bad', ' terrible ', '   d   ', '   no plz   '].each do |invalid_property|
        roster = build(:roster, user: user, participant_properties: ['val_id', invalid_property, 'fine'])
        expect(roster).to be_valid
        expect(roster.participant_properties).to include(invalid_property.strip)
      end
    end

    it 'is invalid with multiple spaces between property words' do
      ['test  property', 'test  HI', 'test all the   things', 'he_llo it is time       to be invalid'].each do |property|
        roster = build(:roster, user: user, participant_properties: [property])
        expect(roster).not_to be_valid
      end
    end
  end

  it 'is invalid with case insensitively duplicate properties' do
    properties = [['SOME thing', 'some THING'].freeze, ['same thing', 'same thing'].freeze,
                  ['123', '123'].freeze, ['good', 'BAD', 'bAD'].freeze].freeze
    properties.each do |property_set|
      roster = build(:roster, user: user, participant_properties: property_set)
      expect(roster).not_to be_valid
      # Make sure that the downcasing hasn't actually persisted.
      expect(roster.participant_properties).to match_array(property_set)
      expect(roster.errors[:participant_properties]).to include(Roster::DUPLICATE_PROPERTIES_ERROR_MESSAGE)
    end
  end

  after(:all) do
    User.destroy_all
    Roster.destroy_all
    Participant.destroy_all
  end
end
