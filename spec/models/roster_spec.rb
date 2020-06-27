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

    it 'downcases participant properties' do
      properties = ['UPPERCASE', 'SUPER HUGE', 'SOME THINGS JUST should not be', 'd', 'No Plz']
      roster = build(:roster, user: user, participant_properties: properties)
      expect(roster).to be_valid
      expect(roster.participant_properties).to match_array(properties.map(&:downcase))
    end
  end

  it 'is invalid with multiple spaces between property words' do
    ['test  property', 'test  HI', 'test all the   things', 'he_llo it is time       to be invalid'].each do |property|
      roster = build(:roster, user: user, participant_properties: [property])
      expect(roster).not_to be_valid
    end
  end

  after(:all) do
    User.destroy_all
    Roster.destroy_all
    Participant.destroy_all
  end
end
