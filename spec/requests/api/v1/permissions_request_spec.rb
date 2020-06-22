require 'rails_helper'

RSpec.describe 'Api::V1::Permissions', type: :request do
  Permission.levels.keys.each do |level|
    context "with #{level} user" do
      let!(:roster) { create(:roster, :multiple_permissions, permissions: [user_permission]) }
      let(:user_permission) { build(:permission, level: level, user: user) }
      let(:user) { create(:user) }

      let(:permission_matrix) do
        Permission.levels.keys.to_h do |perm_level|
          if perm_level == 'owner' && level == 'owner'
            [perm_level, user_permission]
          else
            [perm_level, create(:permission, roster: roster, level: perm_level)]
          end
        end
      end

      before(:each) { sign_in(user) }

      describe 'GET permissions (index)' do
        it 'renders all roster permissions', unless: level == 'viewer' do
          get api_v1_roster_permissions_path(roster)
          expect(response).to have_http_status(:ok)
          parsed = JSON.parse(response.body)
          expect(parsed.count).to eq(roster.permissions.count)
          expect(parsed.map { |json| json['id'] }).to match_array(roster.permissions.map(&:id))
        end

        it 'renders the user\'s permission only', if: level == 'viewer' do
          get api_v1_roster_permissions_path(roster)
          expect(response).to have_http_status(:ok)
          parsed = JSON.parse(response.body)
          expect(parsed.count).to eq(1)
          expect(parsed[0]['id']).to eq(user_permission.id)
          expect(parsed[0]['level']).to eq(user_permission.level)
        end
      end

      describe 'GET permission (show)' do
        it 'renders permission' do
          get api_v1_permission_path(user_permission)
          expect(response).to have_http_status(:ok)
          parsed = JSON.parse(response.body)
          expect(parsed['id']).to eq(user_permission.id)
          expect(parsed['level']).to eq(user_permission.level)
        end
      end

      describe 'POST permission (create)' do
        let(:creation_user) { create(:user) }

        describe 'successfully' do
          shared_examples 'permission creation' do |current_level|
            it "creates #{current_level}" do
              post api_v1_roster_permissions_path(roster),
                   params: { permission: { level: current_level, email: creation_user.email } }
              expect(response).to have_http_status(:created)
              parsed = JSON.parse(response.body)
              expect(Permission.exists?(parsed['id'])).to be true
              expect(parsed['level']).to eq(current_level)
            end
          end

          include_examples 'permission creation', 'owner' if level == 'owner'
          if %w[owner administrator].include?(level)
            %w[administrator operator viewer].each do |test_level|
              include_examples 'permission creation', test_level
            end
          end
        end

        describe 'for a user with a permission already in the roster' do
          let(:user_already_in) { create(:permission, level: :administrator, roster: roster).user }
          it 'denies creation of permission for user with one already', if: %w[owner administrator].include?(level) do
            post api_v1_roster_permissions_path(roster),
                 params: { permission: { level: 'operator', email: user_already_in.email } }
            expect(response).to have_http_status(:bad_request)
          end
        end

        describe 'denies' do
          shared_examples 'denier' do |current_level|
            it "creation of #{current_level} with 403 forbidden" do
              post api_v1_roster_permissions_path(roster),
                   params: { permission: { level: current_level, email: creation_user.email } }
              expect(response).to have_http_status(:forbidden)
            end
          end

          if level == 'administrator'
            include_examples 'denier', 'owner'
          elsif level != 'owner'
            Permission.levels.keys.each do |current_level|
              include_examples 'denier', current_level
            end
          end
        end
      end

      describe 'PATCH permission (update)' do
        describe 'successfully', if: %w[owner administrator].include?(level) do
          shared_examples 'permission update' do |from_level, to_level|
            it "updates from #{from_level} to #{to_level}" do
              patch api_v1_permission_path(permission_matrix[from_level]),
                    params: { permission: { level: to_level } }
              expect(response).to have_http_status(:ok)
              parsed = JSON.parse(response.body)
              expect(parsed['level']).to eq(to_level)
              expect(permission_matrix[from_level].reload.level).to eq(to_level)
            end
          end

          if level == 'owner'
            # Owner can promote anyone to owner.
            %w[administrator operator viewer].each do |from_level|
              include_examples 'permission update', from_level, 'owner'
            end
            # Owner can demote admins
            %w[operator viewer].each do |to_level|
              include_examples 'permission update', 'administrator', to_level
            end
          end
          # Owner and administrators can play with operators and viewers.
          %w[operator viewer].each do |from_level|
            (%w[operator viewer] - [from_level]).each do |to_level|
              include_examples 'permission update', from_level, to_level
            end
          end
        end

        describe 'on owner permission with owner', if: level == 'owner' do
          %w[administrator operator viewer].each do |to_level|
            it "fails to update to #{to_level}" do
              patch api_v1_permission_path(user_permission),
                    params: { permission: { level: to_level } }
              expect(response).to have_http_status(:bad_request)
            end
          end
        end

        describe 'denies', if: Permission.at_most?(level, 'administrator') do
          shared_examples 'denier' do |from_level, to_level|
            it "update from #{from_level} to #{to_level}" do
              patch api_v1_permission_path(permission_matrix[from_level]),
                    params: { permission: { level: to_level } }
              expect(response).to have_http_status(:forbidden)
            end
          end

          # None of the three can go from owner or admin to anything.
          %w[owner administrator].each do |from_level|
            (%w[owner administrator operator viewer] - [from_level]).each do |to_level|
              include_examples 'denier', from_level, to_level
            end
          end
          # Operator and below can't do anything
          if Permission.at_most?(level, 'operator')
            %w[operator viewer].each do |from_level|
              (Permission.levels.keys - [from_level]).each do |to_level|
                include_examples 'denier', from_level, to_level
              end
            end
          end
        end
      end

      describe 'delete permission (DESTROY)' do
        describe 'successfully' do
          shared_examples 'destroy permission' do |destroy_level|
            it "destroys permission of level #{destroy_level}" do
              permission = permission_matrix[destroy_level]
              delete api_v1_permission_path(permission)
              expect(response).to have_http_status(:success)
              expect(Permission.exists?(permission.id)).to be false
            end
          end

          if level == 'owner'
            include_examples 'destroy permission', 'owner'
            include_examples 'destroy permission', 'administrator'
          end

          if Permission.at_least?(level, 'administrator')
            %w[operator viewer].each do |destroy_level|
              include_examples 'destroy permission', destroy_level
            end
          end
        end

        describe 'denies' do
          shared_examples 'denier' do |destroy_level|
            it "destroying #{destroy_level}" do
              permission = permission_matrix[destroy_level]
              delete api_v1_permission_path(permission)
              expect(response).to have_http_status(:forbidden)
              expect(Permission.exists?(permission.id)).to be true
            end
          end

          include_examples 'denier', 'administrator' if Permission.at_most?(level, 'administrator')
          if Permission.at_most?(level, 'operator')
            %w[owner operator viewer].each do |destroy_level|
              include_examples 'denier', destroy_level
            end
          end
        end

        context 'on the user\'s own permission' do
          it 'successfully destroys' do
            delete api_v1_permission_path(user_permission)
            expect(response).to have_http_status(:success)
            expect(Permission.exists?(user_permission.id)).to be false
          end
        end
      end
    end
  end
end
