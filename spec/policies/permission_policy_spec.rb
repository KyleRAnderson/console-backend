require 'rails_helper'

RSpec.describe PermissionPolicy, type: :policy do
  subject { PermissionPolicy }
  let(:users) { permission_matrix.to_h { |k, v| [k, v.user] } }
  let(:owner_permission) { create(:permission, level: :owner, roster: roster) }
  let(:administrator_permission) { create(:permission, level: :administrator, roster: roster) }
  let(:operator_permission) { create(:permission, level: :operator, roster: roster) }
  let(:viewer_permission) { create(:permission, level: :viewer, roster: roster) }
  let(:permission_matrix) { { owner: owner_permission, administrator: administrator_permission, operator: operator_permission, viewer: viewer_permission } }
  let(:roster) { create(:roster) }

  describe '::Scope' do
    context 'within a single roster' do
      before(:each) do
        create_list(:permission, 5, level: :administrator, roster: roster)
        create_list(:permission, 15, level: :administrator, roster: roster)
        create_list(:permission, 20, level: :viewer, roster: roster)
      end

      it 'allows owners, administrators and operators to view all permissions' do
        users.slice(:owner, :administrator, :operator).values.each do |user|
          resolved_scoped = subject::Scope.new(user, roster.permissions.reload).resolve
          expect(resolved_scoped).to match_array(roster.permissions)
        end
      end

      it 'allows viewes acess to only their permission' do
        resolved_scope = subject::Scope.new(viewer_permission.user, roster.permissions).resolve
        expect(resolved_scope).to contain_exactly(viewer_permission)
      end
    end

    context 'with random permissions from different rosters' do
      let(:owner_roster) { create(:roster, :multiple_permissions, user: user_multi_level) }
      let(:admin_roster) { create(:roster, :multiple_permissions) }
      let(:operator_roster) { create(:roster, :multiple_permissions) }
      let(:viewer_roster) { create(:roster, :multiple_permissions) }
      let(:none_roster) { create(:roster, :multiple_permissions) }
      let(:rosters) { [owner_roster, admin_roster, operator_roster, viewer_roster, none_roster] }
      let(:user_viewer_only) { create(:user) }
      let(:user_multi_level) { create(:user) }
      let!(:viewer_permissions) do
        rosters.map { |roster| create(:permission, level: :viewer, user: user_viewer_only, roster: roster) }
      end
      let!(:multi_user_viewer) { create(:permission, level: :viewer, user: user_multi_level, roster: viewer_roster) }
      let(:multi_user_viewable) do
        owner_roster.permissions.reload + admin_roster.permissions.reload +
          operator_roster.permissions.reload + [multi_user_viewer]
      end

      before(:each) do
        create(:permission, level: :administrator, user: user_multi_level, roster: admin_roster)
        create(:permission, level: :operator, user: user_multi_level, roster: operator_roster)
      end

      it 'allows users to view their permissions and those for ' \
         'rosters in which they have priviledge' do
        resolved_scope = subject::Scope.new(user_viewer_only, Permission).resolve
        expect(resolved_scope).to match_array(viewer_permissions)
        resolved_scope = subject::Scope.new(user_multi_level, Permission).resolve
        expect(resolved_scope).to match_array(multi_user_viewable)
      end
    end
  end

  describe :show do
    it 'allows owners, administrators and operators to view all roster permissions' do
      users.slice(:owner, :administrator, :operator).values.each do |user|
        permission_matrix.values.each do |permission|
          expect(subject.new(user, permission)).to permit_action(described_class)
        end
      end
    end

    it 'denies viewers access to all but their own permissions' do
      viewer = viewer_permission.user
      permission_matrix.except(:viewer).values.each do |permission|
        expect(subject.new(viewer, permission)).to forbid_action(described_class)
      end
    end
  end

  describe :create do
    it 'allows owners to create any sort of permission' do
      %i[owner administrator operator viewer].each do |level|
        permission = build(:permission, level: level, roster: roster)
        expect(subject.new(owner_permission.user, permission)).to permit_action(described_class)
      end
    end

    it 'allows administrators to create up to administrators' do
      %i[administrator operator viewer].each do |level|
        permission = build(:permission, level: level, roster: roster)
        expect(subject.new(administrator_permission.user, permission)).to permit_action(described_class)
      end
    end

    it 'denies administrators create for owner' do
      permission = build(:permission, level: :owner, roster: roster)
      expect(subject.new(administrator_permission.user, permission)).to forbid_action(described_class)
    end

    it 'denies creation for operators and viewers' do
      users.slice(:operator, :viewer).values.each do |user|
        %i[owner administrator operator viewer].each do |level|
          permission = build(:permission, level: level, roster: roster)
          expect(subject.new(user, permission)).to forbid_action(described_class)
        end
      end
    end
  end

  describe :update do
    it 'allows owner to update from any level to any level' do
      owner = owner_permission.user
      permission_matrix.each do |from_level, permission|
        permission_matrix.except(from_level).keys.each do |to_level|
          permission.level = to_level
          expect(subject.new(owner, permission)).to permit_action(described_class)
        end
      end
    end

    it 'allows administrator to manage up to administrator' do
      administrator = administrator_permission.user
      permission_matrix.except(:owner).each do |from_level, permission|
        permission_matrix.except(:owner, from_level).keys.each do |to_level|
          permission.level = to_level
          expect(subject.new(administrator, permission)).to permit_action(described_class)
        end
      end
    end

    it 'denies administrator promotion to owner' do
      administrator = administrator_permission.user
      viewer_permission.level = :owner
      expect(subject.new(administrator, viewer_permission)).to forbid_action(described_class)
    end

    it 'denies viewer and operator all access to update' do
      users.slice(:operator, :viewer).values.each do |user|
        permission_matrix.each do |from_level, permission|
          permission_matrix.except(from_level).keys.each do |to_level|
            permission.level = to_level
            expect(subject.new(user, permission)).to forbid_action(described_class)
          end
        end
      end
    end
  end

  describe :destroy do
    describe 'handling their own permission' do
      it 'allows permission owner to destroy their own permission' do
        users.each do |level, user|
          expect(subject.new(user, permission_matrix[level])).to permit_action(described_class)
        end
      end
    end

    describe 'handling other users\' permissions' do
      # Need a permission matrix where the user performing operation won't also own permission.
      let(:manager_users) do
        %i[administrator operator viewer].to_h { |level| [level, create(:permission, level: level, roster: roster).user] }
      end

      it 'allows owners destroy access to all permissions' do
        permission_matrix.values.each do |permission|
          expect(subject.new(owner_permission.user, permission)).to permit_action(described_class)
        end
      end

      it 'allows administrators access to destroy operators and viewers' do
        user = manager_users[:administrator]
        permission_matrix.slice(:operator, :viewer).values.each do |permission|
          expect(subject.new(user, permission)).to permit_action(described_class)
        end
      end

      it 'denies administrators access to destroy owners or administrators' do
        user = manager_users[:administrator]
        expect(subject.new(user, permission_matrix[:administrator])).to forbid_action(described_class)
        expect(subject.new(user, owner_permission)).to forbid_action(described_class)
      end

      it 'denies operators and viewers all destroy access' do
        manager_users.slice(:operator, :viewer).values.each do |user|
          permission_matrix.values.each do |permission|
            expect(subject.new(user, permission)).to forbid_action(described_class)
          end
        end
      end
    end
  end
end
