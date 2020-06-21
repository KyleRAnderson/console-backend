# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Participants', type: :request do
  context 'with logged in user' do
    before(:all) do
      @steve = create(:user)
      create(:full_roster, num_participants: 10,
                           user: @steve, participant_properties: ['one', 'two'])
    end

    after(:all) { @steve.destroy! }

    before(:each) { sign_in(@steve) }

    describe 'POST participants (create)' do
      context 'for a roster with multiple participant properties' do
        it 'creates a new participant with correct values set' do
          post api_v1_roster_participants_path(@steve.rosters.first),
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
    end

    describe 'PATCH participants (update)' do
      let(:participant) { create(:participant, roster: @steve.rosters.first) }
      it 'updates the participant with correct values set' do
        call = expect do
          patch api_v1_participant_path(participant),
            params: { participant: { first: 'testing', last: 'participant' } }
        end
        call.not_to(change { participant.reload.extras })
        expect(response).to have_http_status(:ok)
        parsed = Participant.new.from_json(response.body)
        expect(parsed.first).to eq('testing')
        expect(parsed.last).to eq('participant')
        expect(participant.reload).to eq(parsed)
      end
    end

    describe 'GET participants (index)' do
      it 'returns a pagified list of participants in the roster' do
        get api_v1_roster_participants_path(@steve.rosters.first),
            params: { page: 1, per_page: @steve.rosters.first.participants.count }
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('participants')
        expect(parsed_response).to have_key('num_pages')
        expect(parsed_response['participants'].count).to eq(@steve.rosters.first.participants.count)
      end

      context 'while requesting more participants than can fit on one page' do
        it 'paginates properly' do
          participants_per_page = (@steve.rosters.first.participants.count / 2).ceil
          get api_v1_roster_participants_path(@steve.rosters.first),
              params: { page: 1, per_page: participants_per_page }

          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to have_key('participants')
          expect(parsed_response).to have_key('num_pages')
          expect(parsed_response['num_pages']).to eq(2)
          first_participants = parsed_response['participants']
          expect(first_participants.count).to eq(participants_per_page)

          get api_v1_roster_participants_path(@steve.rosters.first),
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
    end

    describe 'GET participant (show)' do
      it 'returns the information for that participant' do
        roster = @steve.rosters.first
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
      let(:roster_no_properties) do
        create(:full_roster,
               num_participants: 15, num_participant_properties: 0, user: @steve)
      end

      it 'can be created without specifying participant extras' do
        post api_v1_roster_participants_path(roster_no_properties),
             params: { participant: { first: 'pete', last: 'mator' } }
        expect(response).to have_http_status(:created)
        participant = JSON.parse(response.body)
        expect(participant['first']).to eq('pete')
        expect(participant['last']).to eq('mator')
      end
    end

    describe 'DELETE participant (destroy)' do
      it 'deletes the participant successfully' do
        deletion_participant = @steve.rosters.first.participants.first
        delete api_v1_participant_path(deletion_participant)
        expect(response).to have_http_status(:success)
        expect(Participant.exists?(deletion_participant.id)).to be false
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
