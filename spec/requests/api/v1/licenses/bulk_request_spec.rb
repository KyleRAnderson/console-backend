require 'rails_helper'

RSpec.describe 'Api::V1::Licenses::Bulks', type: :request do
  Permission.levels.keys.each do |level|
    context "with #{level} user" do
      let(:user) { create(:user) }
      let(:user_permission) { build(:permission, level: level, user: user) }
      let(:roster) { create(:roster, permissions: [user_permission]) }
      let(:hunt) { create(:hunt, roster: roster) }

      before(:each) { sign_in(user) }

      describe :create do
        let(:params) { {} }
        shared_examples 'denies request' do
          it 'denies request with 403 forbidden', if: Permission.at_most?(level, :viewer) do
            extra_params = params.present? ? { params: params } : {}
            expect { post(bulk_api_v1_hunt_licenses_path(hunt), **extra_params) }.not_to(change { License.count })
            expect(response).to have_http_status(:forbidden)
          end
        end

        shared_examples 'successfully does nothing' do
          it 'does nothing and returns no success and no errors', if: Permission.at_least?(level, :operator) do
            expect { post bulk_api_v1_hunt_licenses_path(hunt) }.not_to(change { License.count })
            expect(response).to have_http_status(:ok)
            parsed = JSON.parse(response.body)
            expect(parsed).to have_key('succeeded')
            expect(parsed).to have_key('failed')
            expect(parsed['succeeded']).to be_empty
            expect(parsed['failed']).to be_empty
          end
        end

        context 'with no participants in the roster' do
          include_examples 'denies request'
          include_examples 'successfully does nothing' if Permission.at_least?(level, :operator)
        end

        context 'when all participants have a license in the hunt' do
          let(:roster) { create(:roster_with_participants, num_participants: 23, permissions: [user_permission]) }
          let!(:hunt) { create(:hunt_with_licenses, roster: roster) }

          include_examples 'denies request'
          include_examples 'successfully does nothing' if Permission.at_least?(level, :operator)
        end

        context 'when some participants have a license in the hunt' do
          let(:with_license) { create_list(:participant, 13, roster: roster) }
          let!(:no_license) { create_list(:participant, 11, roster: roster) }

          before(:each) do
            with_license.each { |participant| create(:license, participant: participant, hunt: hunt) }
          end

          shared_examples 'creates licenses for expected' do
            it 'creates licenses for participants with no license in the hunt' do
              expect { post bulk_api_v1_hunt_licenses_path(hunt) }.to(change { License.count }.by(no_license.size))
              expect(response).to have_http_status(:created)
              parsed = JSON.parse(response.body)
              expect(parsed).to have_key('succeeded')
              expect(parsed).to have_key('failed')
              expect(parsed['succeeded'].size).to eq(no_license.size)
              expect(License.where(id: parsed['succeeded']).pluck(:participant_id)).to match_array(no_license.map(&:id))
              expect(parsed['failed']).to be_empty
            end
          end

          context 'with no other hunts' do
            include_examples 'denies request'
            include_examples 'creates licenses for expected' if Permission.at_least?(level, :operator)
          end

          context 'with other hunts in which some participants have licenses' do
            before(:each) do
              other_hunts = create_list(:hunt, 2, roster: roster)
              other_hunts.each do |hunt|
              end
            end

            include_examples 'denies request'
            include_examples 'creates licenses for expected' if Permission.at_least?(level, :operator)
          end
          context 'with participants in other rosters' do
            before(:each) { create_list(:participant, 10) }
            include_examples 'denies request'
            include_examples 'creates licenses for expected' if Permission.at_least?(level, :operator)
          end
        end

        describe 'upon invalid participants sent' do
          let(:other_participants) { create_list(:participant, 21) }
          let(:other_participant_ids) { other_participants.map(&:id) }

          context 'with no other participants requested to create' do
            let(:params) { { licenses: { participant_ids: other_participant_ids } } }
            include_examples 'denies request'
            it 'creates no licenses', if: Permission.at_least?(level, :operator) do
              expect do
                post bulk_api_v1_hunt_licenses_path(hunt), params: params
              end.not_to(change { License.count })
              expect(response).to have_http_status(:multi_status)
              parsed = JSON.parse(response.body)
              expect(parsed).to have_key('failed')
              expect(parsed['failed']).to all have_key('participant_id')
              expect(parsed['failed'].map { |license| license['participant_id'] }).to match_array(other_participant_ids)
            end
          end

          context 'with other valid participants requested to be created' do
            let(:valid_participants) { create_list(:participant, 5, roster: roster) }
            let(:valid_participant_ids) { valid_participants.map(&:id) }
            let(:all_participants) { valid_participants + other_participants }
            let(:all_participant_ids) { valid_participant_ids + other_participant_ids }
            let(:params) { { participant_ids: all_participant_ids } }

            include_examples 'denies request'
            it 'creates licenses for the valid participants but not for the invalid ones', if: Permission.at_least?(level, :operator) do
              expect do
                post bulk_api_v1_hunt_licenses_path(hunt), params: { licenses: { participant_ids: all_participant_ids } }
              end.to(change { License.count }.by(valid_participants.size))
              expect(response).to have_http_status(:multi_status)
              parsed = JSON.parse(response.body)
              expect(parsed).to have_key('failed')
              expect(parsed['failed'].map { |license| license['participant_id'] }).to match_array(other_participant_ids)
              expect(parsed).to have_key('succeeded')
              expect(License.where(id: parsed['succeeded']).map(&:participant_id)).to match_array(valid_participant_ids)
            end
          end
        end

        context 'when specifying specific participants to create licenses for' do
          let(:no_create_participants) { create_list(:participant, 13, roster: roster) }
          let(:create_participants) { create_list(:participant, 11, roster: roster) }
          let(:create_participant_ids) { create_participants.map(&:id) }
          let(:params) { { licenses: { participant_ids: create_participant_ids } } }

          include_examples 'denies request'
          it 'only creates licenses for the specified participants', if: Permission.at_least?(level, :operator) do
            expect { post bulk_api_v1_hunt_licenses_path(hunt), params: params }.to(change { License.count }.by(create_participants.size))
            expect(response).to have_http_status(:created)
            parsed = JSON.parse(response.body)
            expect(parsed).to have_key('succeeded')
            expect(parsed).to have_key('failed')
            expect(License.where(id: parsed['succeeded']).map(&:participant_id)).to match_array(create_participant_ids)
            expect(parsed['failed']).to be_empty
          end
        end
      end
    end
  end
end
