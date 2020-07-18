require 'rails_helper'

RSpec.describe 'Api::V1::Matches::Edits', type: :request do
  let(:user) { create(:user) }

  Permission.levels.keys.each do |level|
    context "with #{level} user" do
      let(:user_permission) { build(:permission, level: level, user: user) }

      before(:each) { sign_in(user) }
      describe :create do
        shared_examples 'denies access' do
          it 'denies access with 403 forbidden', if: Permission.at_most?(level, :viewer) do
            expect do
              post api_v1_hunt_matches_edits_path(hunt), params: { edit_info: { pairings: pairings } }
            end.not_to(change { Match.count })
            expect(response).to have_http_status(:forbidden)
          end
        end

        describe 'invalid calls' do
          # Evenness of num_participants so as to get pairs of 2 nicely. Otherwise, we would make an invalid request.
          let(:roster) { create(:roster_with_participants, permissions: [user_permission], num_participants: 22) }
          let(:hunt) { create(:hunt_with_licenses, roster: roster) }
          let(:license_ids) { hunt.licenses.pluck(:id) }
          context 'with no pairing arguments' do
            let(:pairings) { license_ids.each_slice(2).to_a }

            it 'renders bad request with error messages', if: Permission.at_least?(level, :operator) do
              expect do
                post api_v1_hunt_matches_edits_path(hunt)
              end.not_to(change { Match.count })
              expect(response).to have_http_status(:unprocessable_entity)
              # Expecting a plaintext response.
              parsed = JSON.parse(response.body)
              expect(parsed['messages']).to include(Match::EMPTY_PAIRINGS_ERROR_MESSAGE)
            end

            include_examples 'denies access'
          end

          context 'with duplicate license IDs' do
            shared_examples 'duplicate id request' do
              it 'renders an error with proper message and distinct list of duplicate IDs',
                 if: Permission.at_least?(level, :operator) do
                expect do
                  post api_v1_hunt_matches_edits_path(hunt), params: { edit_info: { pairings: pairings } }
                end.not_to(change { Match.count })
                expect(response).to have_http_status(:unprocessable_entity)
                parsed = JSON.parse(response.body)
                expect(parsed).to have_key('messages')
                expect(parsed).to have_key('duplicates')
                expect(parsed['messages']).to include(Match::DUPLICATE_LICENSE_IDS_ERROR_MESSAGE)
                expect(parsed['duplicates']).to match_array(duplicate_ids)
                expect(parsed['duplicates'].uniq).to eq(parsed['duplicates'])
              end

              include_examples 'denies access'
            end

            describe 'for all licenses' do
              let(:duplicate_ids) { license_ids }
              let(:pairings) { 2.times.map { license_ids }.transpose }
              include_examples 'duplicate id request'
            end

            describe 'for only some licenses' do
              let(:duplicate_ids) { license_ids.first }
              let(:pairings) { license_ids[1..] + 2.times.map { license_ids.first } }
              include_examples 'duplicate id request'
            end
          end

          context 'with improper pairings' do
            let(:roster) { create(:roster, permissions: [user_permission]) }
            let(:hunt) { create(:hunt, roster: roster) }

            shared_examples 'invalid pairing lengths' do
              it 'renders an error message explaining the invalid lengths', if: Permission.at_least?(level, :operator) do
                expect do
                  post api_v1_hunt_matches_edits_path(hunt), params: { edit_info: { pairings: pairings } }
                end.not_to(change { Match.count })
                expect(response).to have_http_status(:unprocessable_entity)
                parsed = JSON.parse(response.body)
                expect(parsed).to have_key('messages')
                expect(parsed['messages']).to include(Match::IMPROPER_PAIRINGS)
              end

              include_examples 'denies access'
            end

            describe 'of 3 licenses' do
              let(:pairings) { 4.times.map { create_list(:license, 3, hunt: hunt) } }
              include_examples 'invalid pairing lengths'
            end

            describe 'of various number of licenses' do
              let(:pairings) do
                [5, 10, 3, 2, 4, 2].map do |pairing_length|
                  create_list(:license, pairing_length, hunt: hunt).map(&:id)
                end
              end

              include_examples 'invalid pairing lengths'
            end

            describe 'containing single licenses' do
              let(:pairings) do
                [2, 2, 2, 1, 2].map do |pairing_length|
                  create_list(:license, pairing_length, hunt: hunt).map(&:id)
                end
              end

              include_examples 'invalid pairing lengths'
            end
          end
        end

        describe 'valid calls' do
          let(:roster) { create(:roster, permissions: [user_permission]) }
          let(:hunt) { create(:hunt, roster: roster) }
          # Evenness of numbers is important here. Otherwise, it's an invalid request.
          let(:unmatched_licenses) { create_list(:license, 12, hunt: hunt) }
          let(:pairings) { unmatched_licenses.map(&:id).each_slice(2).to_a }

          context 'with unmatched licenses' do
            shared_examples 'create for unmatched licenses' do |expected_round_number|
              it 'creates matches, destroys nothing', if: Permission.at_least?(level, :operator) do
                expect do
                  post api_v1_hunt_matches_edits_path(hunt), params: { edit_info: { pairings: pairings } }, as: :json
                end.to enqueue_job(MatchEditorJob).with do |actual_round, actual_pairings|
                  expect(actual_pairings).to match_array(pairings)
                  expect(actual_round.number).to eq(expected_round_number)
                end
              end

              include_examples 'denies access'
            end

            context 'with no pre-existing round' do
              include_examples 'create for unmatched licenses', 1
            end

            context 'with a pre-existing round' do
              # Has to be even number of licenses for matches to be created properly.
              let(:matched_licenses) { create_list(:license, 16, hunt: hunt) }

              before(:each) do
                2.times.each do
                  round = create(:round, hunt: hunt)
                  matched_licenses.shuffle.each_slice(2) { |pair| create(:match, round: round, licenses: pair) }
                end
              end

              include_examples 'create for unmatched licenses', 3
            end
          end
        end
      end
    end
  end

  context 'with no authenticated user' do
    let(:hunt) { create(:hunt_with_licenses, num_licenses: 20) }
    let!(:round) { create(:round_with_matches, hunt: hunt) }

    it 'rejects request with 401' do
      expect do
        post api_v1_hunt_matches_edits_path(hunt), params: { edit_info: { pairings: hunt.licenses.map(&:id).each_slice(2).to_a } }
      end.not_to(change { Match.count })
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
