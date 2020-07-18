# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Participants', type: :request do
  Permission.levels.keys.each do |level|
    context "with #{level} user" do
      let!(:roster) { create(:full_roster, permissions: [user_permission], participant_properties: ['one', 'two']) }
      let(:user_permission) { build(:permission, level: level, user: user) }
      let(:user) { create(:user) }

      before(:each) { sign_in(user) }

      describe 'POST participants (create)' do
        context 'for a roster with multiple participant properties' do
          it 'creates a new participant with correct values set', unless: Permission.at_most?(level, :viewer) do
            post api_v1_roster_participants_path(roster),
                 params: { participant: { first: 'test', last: 'gilly',
                                         extras: { 'one' => 'test1', 'two' => 'test2' } } }
            expect(response).to have_http_status(:created)
            participant = Participant.new.from_json(response.body)
            expect(participant.first).to eq('test')
            expect(participant.last).to eq('gilly')
            expect(participant.extras['one']).to eq('test1')
            expect(participant.extras['two']).to eq('test2')
            expect(Participant.find_by(id: participant['id'])).to eq(participant)
          end
        end

        it 'denies access with 403 forbidden', if: Permission.at_most?(level, :viewer) do
          post api_v1_roster_participants_path(roster),
               params: { participant: { first: 'test', last: 'gilly',
                                       extras: { 'one' => 'test1', 'two' => 'test2' } } }
          expect(response).to have_http_status(:forbidden)
          expect(Participant.find_by(first: 'test', last: 'gilly')).to be_blank
        end
      end

      describe 'PATCH participants (update)' do
        let(:participant) { create(:participant, roster: roster) }

        it 'updates the participant with correct values set', unless: Permission.at_most?(level, :viewer) do
          expect do
            patch api_v1_participant_path(participant),
              params: { participant: { first: 'testing', last: 'participant' } }
          end.not_to(change { participant.reload.extras })
          expect(response).to have_http_status(:ok)
          parsed = Participant.new.from_json(response.body)
          expect(parsed.first).to eq('testing')
          expect(parsed.last).to eq('participant')
          expect(participant.reload).to eq(parsed)
        end

        it 'denies access with 403 forbidden', if: Permission.at_most?(level, :viewer) do
          patch api_v1_participant_path(participant), params: { participant: { first: 'testing', last: 'participant' } }
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe 'GET participants (index)' do
        it 'returns a paginated list of participants in the roster' do
          get api_v1_roster_participants_path(roster),
              params: { page: 1, per_page: roster.participants.count }
          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to have_key('participants')
          expect(parsed_response).to have_key('num_pages')
          expect(parsed_response['participants'].count).to eq(roster.participants.count)
        end

        context 'while requesting more participants than can fit on one page' do
          it 'paginates properly' do
            participants_per_page = (roster.participants.size * 0.5).ceil
            get api_v1_roster_participants_path(roster),
                params: { page: 1, per_page: participants_per_page }

            expect(response).to have_http_status(:ok)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response).to have_key('participants')
            expect(parsed_response).to have_key('num_pages')
            expect(parsed_response['num_pages']).to eq(2)
            first_participants = parsed_response['participants']
            expect(first_participants.count).to eq(participants_per_page)

            get api_v1_roster_participants_path(roster),
                params: { page: 2, per_page: participants_per_page }
            expect(response).to have_http_status(:ok)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response).to have_key('participants')
            expect(parsed_response).to have_key('num_pages')
            expect(parsed_response['num_pages']).to eq(2)
            second_participants = parsed_response['participants']
            expect(second_participants.count).to be <= participants_per_page

            expect(first_participants).not_to eq(second_participants)
          end
        end

        context 'with a filter on hunt' do
          let(:roster) { create(:roster_with_participants, num_participants: 23, permissions: [user_permission]) }
          let(:hunt) { create(:hunt, roster: roster) }

          context 'with no participants in the hunt' do
            it 'returns all participants in the roster' do
              get api_v1_roster_participants_path(roster), params: { page: 1, per_page: roster.participants.size, exclude_hunt_id: hunt.id }
              expect(response).to have_http_status(:ok)
              parsed = JSON.parse(response.body)
              expect(parsed).to have_key('participants')
              expect(parsed['participants'].map { |p| p['id'] }).to match_array(roster.participants.pluck(:id))
            end
          end

          context 'with all participants in the hunt' do
            before(:each) do
              roster.participants.each { |participant| create(:license, participant: participant, hunt: hunt) }
            end
            it 'returns no results' do
              get api_v1_roster_participants_path(roster), params: { page: 1, per_page: roster.participants.size, exclude_hunt_id: hunt.id }
              expect(response).to have_http_status(:ok)
              parsed = JSON.parse(response.body)
              expect(parsed).to have_key('participants')
              expect(parsed['participants']).to be_empty
            end
          end

          context 'with some participants with licenses' do
            let(:without_licenses) { roster.participants.first(10) }

            before(:each) do
              # Just to make sure that these participants don't get picked up, being outside of the roster.
              create_list(:participant, 11)
              (roster.participants - without_licenses).each { |participant| create(:license, hunt: hunt, participant: participant) }
            end

            it 'returns participants withot licenses' do
              get api_v1_roster_participants_path(roster), params: { page: 1, per_page: roster.participants.size, exclude_hunt_id: hunt.id }
              expect(response).to have_http_status(:ok)
              parsed = JSON.parse(response.body)
              expect(parsed).to have_key('participants')
              expect(parsed['participants'].map { |p| p['id'] }).to match_array(without_licenses.map(&:id))
            end
          end
        end
      end

      describe 'GET participant (show)' do
        it 'returns the information for that participant' do
          expected_participant = roster.participants.first
          get api_v1_participant_path(expected_participant)
          expect(response).to have_http_status(:ok)
          participant = JSON.parse(response.body)
          expect(participant['first']).to eq(expected_participant.first)
          expect(participant['last']).to eq(expected_participant.last)
          expect(participant['extras']).to have_key('one')
          expect(participant['extras']).to have_key('two')
        end
      end

      context 'for a roster with no participant properties' do
        let!(:roster) do
          create(:full_roster,
                 num_participants: 15, num_participant_properties: 0, permissions: [user_permission])
        end

        it 'can be created without specifying participant extras', if: Permission.at_least?(level, :operator) do
          post api_v1_roster_participants_path(roster),
               params: { participant: { first: 'pete', last: 'mator' } }
          expect(response).to have_http_status(:created)
          participant = JSON.parse(response.body)
          expect(participant['first']).to eq('pete')
          expect(participant['last']).to eq('mator')
        end
      end

      describe 'DELETE participant (destroy)' do
        it 'deletes the participant successfully', if: Permission.at_least?(level, :operator) do
          deletion_participant = roster.participants.first
          delete api_v1_participant_path(deletion_participant)
          expect(response).to have_http_status(:success)
          expect(Participant.exists?(deletion_participant.id)).to be false
        end

        it 'denies destroy access', if: Permission.at_most?(level, :viewer) do
          delete api_v1_participant_path(roster.participants.first)
          expect(response).to have_http_status(:forbidden)
          expect(Participant.exists?(roster.participants.first.id)).to be true
        end
      end

      describe 'POST participants/upload (upload)' do
        let!(:roster) { create(:roster, permissions: [user_permission], participant_properties: ['test']) }
        let(:wrong_extension) { fixture_file_upload('files/wrong_extension.tar') }
        let(:malformed_csv) { fixture_file_upload('files/malformed_csv.csv') }
        let(:invalid_participants) { fixture_file_upload('files/invalid_participants.csv') }
        let(:valid_file) { fixture_file_upload('files/valid.csv') }

        if Permission.at_least?(level, :operator)
          shared_examples 'bad upload' do
            it 'refuses file with error' do
              post upload_api_v1_roster_participants_path(roster), params: { file: file }
              expect(response).to have_http_status(:bad_request)
              expect(response.body).to be_a String
            end
          end

          context 'with wrong file extension' do
            let(:file) { wrong_extension }
            include_examples 'bad upload'
          end
          context 'with malformed CSV file' do
            let(:file) { malformed_csv }
            include_examples 'bad upload'
          end

          it 'doesn\'t upload any participants if any are invalid' do
            post upload_api_v1_roster_participants_path(roster), params: { file: invalid_participants }
            expect(response).to have_http_status(:unprocessable_entity)
            body = JSON.parse(response.body)
            # No participants should have been created.
            expect(roster.participants.reload.size).to be_zero
            expect(body).to be_an Array
            expect(body.size).to eq(2)
            body.each do |participant_error|
              expect(participant_error).to have_key('first')
              expect(participant_error).to have_key('last')
              expect(participant_error).to have_key('extras')
              expect(participant_error).to have_key('errors')
              expect(participant_error['errors']).to be_a Hash
            end
          end

          it 'uploads and processes a valid CSV file' do
            post upload_api_v1_roster_participants_path(roster), params: { file: valid_file }
            expect(response).to have_http_status(:created)
            expect(response.body).to be_blank
            expect(roster.participants.reload.size).to eq(33)
            33.times do |i|
              expect(roster.participants.find_by(first: "First_#{i + 1}", last: "Last_#{i + 1}")).not_to be_nil
            end
          end
        end

        it 'denies the upload request', if: Permission.at_most?(level, :viewer) do
          post upload_api_v1_roster_participants_path(roster), params: { file: valid_file }
          expect(response).to have_http_status(:forbidden)
          expect(roster.participants.reload.size).to be_zero
        end
      end
    end
  end

  context 'without authorized user' do
    it 'returns 401 for all requests' do
      steve = create(:user_with_rosters, num_rosters: 4)
      roster = create(:full_roster, user: steve, num_participants: 10)

      get api_v1_roster_participants_path(steve.rosters.first)
      expect(response).to have_http_status(:unauthorized)

      get api_v1_participant_path(roster.participants.first)
      expect(response).to have_http_status(:unauthorized)

      post api_v1_roster_participants_path(steve.rosters.first)
      expect(response).to have_http_status(:unauthorized)

      delete api_v1_participant_path(roster.participants.last)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'with incorrect authorized user' do
    before(:each) do
      @right_user = create(:user_with_rosters, num_rosters: 3)
      @wrong_user = create(:user_with_rosters, num_rosters: 10)
      sign_in(@right_user)
    end

    describe 'requesting existing participant that user doesn\'t have authorization for' do
      it 'returns 404 not found' do
        get api_v1_participant_path(@wrong_user.rosters.first.participants.first)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'requesting participants for a roster that the user doesn\t have authorization for' do
      it 'returns 404 not found' do
        get api_v1_roster_participants_path(@wrong_user.rosters.first)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
