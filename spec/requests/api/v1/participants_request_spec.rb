# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Participants', type: :request do
  describe 'with logged in user' do
    before(:all) do
      @steve = create(:user, num_rosters: 0)
      create(:roster_with_participants_hunts, num_participants: 10,
                                              user: @steve, participant_properties: ['one', 'two'])
      sign_in_user(@steve)
    end

    after(:all) { @steve.destroy! }

    describe 'GET participants (index)' do
      it 'returns a pagified list of participants in the roster' do
        get api_v1_roster_participants_path(@steve.rosters.first), headers: @headers,
                                                                   params: { page: 1, per_page: @steve.rosters.first.participants.count }
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('participants')
        expect(parsed_response).to have_key('num_pages')
        expect(parsed_response['participants'].count).to eq(@steve.rosters.first.participants.count)
      end

      describe 'with results going over one page' do
        it 'pagifies properly' do
          participants_per_page = (@steve.rosters.first.participants.count / 2).ceil
          get api_v1_roster_participants_path(@steve.rosters.first), headers: @headers,
                                                                     params: { page: 1, per_page: participants_per_page }

          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to have_key('participants')
          expect(parsed_response).to have_key('num_pages')
          expect(parsed_response['num_pages']).to eq(2)
          first_participants = parsed_response['participants']
          expect(first_participants.count).to eq(participants_per_page)

          get api_v1_roster_participants_path(@steve.rosters.first), headers: @headers,
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
        get api_v1_roster_participant_path(roster, expected_participant), headers: @headers
        expect(response).to have_http_status(:ok)
        participant = JSON.parse(response.body)
        expect(participant['first']).to eq(expected_participant.first)
        expect(participant['last']).to eq(expected_participant.last)
        expect(participant['extras']).to have_key('one')
        expect(participant['extras']).to have_key('two')
      end
    end
  end

  describe 'without authorized user' do
    it 'returns 401 for all requests' do
      steve = create(:user, num_rosters: 4)
      roster = create(:roster_with_participants_hunts, user: steve, num_participants: 10)

      get api_v1_roster_participants_path(steve.rosters.first)
      expect(response).to have_http_status(:unauthorized)

      get api_v1_roster_participant_path(roster, roster.participants.first)
      expect(response).to have_http_status(:unauthorized)

      post api_v1_roster_participants_path(steve.rosters.first)
      expect(response).to have_http_status(:unauthorized)

      delete api_v1_roster_participant_path(roster, roster.participants.last)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'with incorrect authorized user' do
    before(:each) do
      @right_user = create(:user, num_rosters: 3)
      @wrong_user = create(:user, num_rosters: 10)
      sign_in_user(@right_user)
    end

    describe 'GET /api/v1/rosters/[valid_roster_id]/participants/[wrong_participant_id]' do
      it 'returns 404 not found' do
        get api_v1_roster_participant_path(@right_user.rosters.first, @wrong_user.rosters.first.participants.first), headers: @headers
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET /api/v1/rosters/[wrong_roster_id]/participants' do
      it 'returns 404 not found' do
        get api_v1_roster_participants_path(@wrong_user.rosters.first), headers: @headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
