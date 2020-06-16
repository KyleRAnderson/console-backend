require 'rails_helper'

RSpec.describe Roster, type: :model do
  let(:user) { create(:user) }

  it 'deletes associated participants upon destroy' do
    roster = create(:full_roster, user: user, num_participants: 100)
    roster.destroy!

    expect(Roster.count).to eq(0)
    expect(Participant.count).to eq(0)
  end

  it 'strips participant properties before validation' do
    [' no good', ' also bad', ' terrible ', '   d   ', '   no plz   '].each do |invalid_property|
      roster = build(:roster, user: user, participant_properties: ['valid', invalid_property, 'fine'])
      expect(roster).to be_valid
      expect(roster.participant_properties).to include(invalid_property.strip)
    end
  end

  after(:all) do
    User.destroy_all
    Roster.destroy_all
    Participant.destroy_all
  end
end
