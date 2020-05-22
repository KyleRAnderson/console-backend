require 'rails_helper'

RSpec.describe Roster, type: :model do
  it 'deletes associated participants upon destroy' do
    user = create(:user, num_rosters: 0)
    roster = create(:roster_with_participants_hunts, user: user, num_participants: 100)
    roster.destroy!

    expect(Roster.count).to eq(0)
    expect(Participant.count).to eq(0)
  end

  after(:all) do
    User.destroy_all
    Roster.destroy_all
    Participant.destroy_all
  end
end
