require 'rails_helper'

RSpec.describe User, type: :model do
  it 'deletes all associated rosters, participants upon deletion, as the owner' do
    user = create(:user)
    create_list(:full_roster, 15, user: user)
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
