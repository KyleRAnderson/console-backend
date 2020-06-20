require 'rails_helper'

def filter_users(levels)
  levels = levels.map(&:to_s)
  users_to_policy(users.filter { |key, _| levels.include?(key) }
    .values)
end

def users_to_policy(users)
  users.map { |user| subject.new(user, roster) }
end

RSpec.fdescribe RosterPolicy do
  subject { RosterPolicy }

  let(:users) do
    Permission.levels.keys.to_h do |level|
      [level, create(:permission, roster: roster, level: level).user]
    end
  end
  let(:roster) { create(:roster) }

  describe 'roster scope' do
    let(:user) { create(:user) }
    let!(:permitted_rosters) do
      %i[owner administrator operator viewer].map do |level|
        roster = create(:roster) # Generates owner for us too.
        # Relies on the assignment to owner kicking out the current owner.
        create(:permission, roster: roster, user: user, level: level)
        roster
      end
    end
    let!(:unauthorized_rosters) { create_list(:roster, 5) }
    let(:resolved_scope) { subject::Scope.new(user, Roster).resolve }

    it 'filters out rosters to which the user has no permission' do
      expect(resolved_scope).to match_array(permitted_rosters)
    end
  end

  it 'doesn\'t authorize the user for anything but create with no permission' do
    none_user = create(:permission).user
    %i[index show update destroy].each do |action|
      expect(subject.new(none_user, roster)).to forbid_action(action)
    end
  end

  describe :index do
    it 'denies operators, viewers and no permissions' do
      expect(filter_users(%w[operator viewer])).to all forbid_action(described_class)
    end

    it 'allows owners and administrators' do
      expect(filter_users(%w[owner administrator])).to all permit_action(described_class)
    end
  end

  describe :show do
    it 'permits users with a permission in the roster' do
      expect(users_to_policy(users)).to all permit_action(described_class)
    end
  end

  describe :create do
    it 'allows all users to create rosters' do
      expect(subject.new(create(:user), roster)).to permit_action(described_class)
    end
  end

  describe :update do
    it 'denies operators and viewers' do
      expect(filter_users(%w[operator viewer])).to all forbid_action(described_class)
    end

    it 'permits owners and administrators' do
      expect(filter_users(%w[owner administrator])).to all permit_action(described_class)
    end
  end

  describe :destroy do
    it 'denies all but owner' do
      expect(filter_users(%w[administrator operator viewer])).to all forbid_action(described_class)
    end

    it 'permits owners' do
      expect(subject.new(users['owner'], roster)).to permit_action(described_class)
    end
  end
end
