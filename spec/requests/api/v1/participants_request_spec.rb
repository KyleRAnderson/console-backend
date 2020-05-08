# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Participants', type: :request do
  describe 'with logged in user' do
    before(:all) do
      @steve = create(:user, num_rosters: 0)
      create(:roster, num_participants: 1,
                      user: @steve, participant_properties: ['one', 'two'])
      post user_session_path, params: { user: {
                                email: @steve.email,
                                password: DEFAULT_PASSWORD,
                              } }
      token = response.headers['Authorization']
      @headers = { 'Authorization': token }
    end

    after(:all) { @steve.destroy! }

    describe 'GET participants (index)' do
      it 'returns a list of all the participants in the roster' do
        get api_v1_roster_participants_path(@steve.rosters.first), headers: @headers
        expect(response).to have_http_status(:ok)
        participants = JSON.parse(response.body)
        expect(participants.count).to eq(@steve.rosters.first.participants.count)
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
      end
    end
  end

  describe 'without authorized user' do
    it 'returns 401 for all requests' do
      steve = create(:user, num_rosters: 4)
      roster = create(:roster, user: steve, num_participants: 10)

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
      post user_session_path, params: {
                                user: {
                                  email: @right_user.email,
                                  password: DEFAULT_PASSWORD,
                                },
                              }
      @headers = { 'Authorization': response.headers['Authorization'] }
    end

    describe 'GET /api/v1/rosters/[valid_roster_id]/participants/[wrong_participant_id]' do
      it 'returns 404 not found' do
        get api_v1_roster_participant_path(@right_user.rosters.first, @wrong_user.rosters.first.participants.first), headers: @headers
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET /api/v1/rosters/[wrong_roster_id]/participants' do
      it 'returns 404 not fond' do
        get api_v1_roster_participants_path(@wrong_user.rosters.first), headers: @headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
