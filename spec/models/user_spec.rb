require 'rails_helper'

RSpec.describe User, type: :model do
  it 'deletes all associated participants and models upon destruction' do
    user = create(:user, num_rosters: 0)
    create_list(:roster_with_participants_hunts, 15, user: user)
    user.destroy!
    expect(User.count).to eq(0)
    expect(Roster.count).to eq(0)
    expect(Participant.count).to eq(0)
  end

  after(:all) do
    User.destroy_all
    Roster.destroy_all
    Participant.destroy_all
  end
end
