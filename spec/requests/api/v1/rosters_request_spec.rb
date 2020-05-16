require 'rails_helper'

RSpec.describe 'Api::V1::Rosters', type: :request do
  describe 'with logged in user' do
    before(:all) do
      @steve = create(:user, num_rosters: 0)
      create(:roster, num_participant_properties: 3, user: @steve)
      post user_session_path, params: {
                                user: {
                                  email: @steve.email,
                                  password: DEFAULT_PASSWORD,
                                },
                              }
      token = response.headers['Authorization']
      @headers = { 'Authorization': token }
    end

    after(:all) { @steve.destroy! }

    describe 'POST /api/v1/rosters' do
      describe 'with no participant properties' do
        it 'creates a new roster, with correct properties' do
          post api_v1_rosters_path, headers: @headers,
                                    params: { roster: { name: 'Test roster 1' } }
          expect(response).to have_http_status(:created)
          roster = JSON.parse(response.body)
          expect(roster['id']).not_to be_empty
          expect(roster['name']).to eq('Test roster 1')
          expect(roster['user_id']).to eq(@steve.id)
          expect(roster['participant_properties']).to be_empty
        end

        describe 'with empty string participant properties' do
          it 'responds with an error' do
            post api_v1_rosters_path, headers: @headers,
                                      params: {
                                        roster: {
                                          name: 'Testing rosters',
                                          participant_properties: ['something', ''],
                                        },
                                      }
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end

      describe 'with participant properties' do
        it 'creates a new roster, with correct properties' do
          post api_v1_rosters_path, headers: @headers,
                                    params: { roster: { name: 'Test roster 2',
                                                       participant_properties: ['one', 'two', 'three'] } }
          expect(response).to have_http_status(:created)

          roster = JSON.parse(response.body)
          expect(roster['id']).not_to be_empty
          expect(roster['name']).to eq('Test roster 2')
          expect(roster['user_id']).to eq(@steve.id)
          expect(roster['participant_properties'].count).to eq(3)
          expect(roster['participant_properties'][0]).to eq('one')
          expect(roster['participant_properties'][1]).to eq('two')
          expect(roster['participant_properties'][2]).to eq('three')
        end
      end
    end

    describe 'GET api/v1/rosters/[roster_id] (show)' do
      it 'loads the roster with the given id successfully' do
        get api_v1_roster_path(@steve.rosters.first), headers: @headers
        expect(response).to have_http_status(:success)
        roster = JSON.parse(response.body)
        expect(roster['user_id']).to eq(@steve.id)
        expect(roster['name']).to eq(@steve.rosters.first.name)
        expect(roster['participant_properties'].count).to eq(3)
      end

      it 'returns 404 not found upon providing an inexistent roster id' do
        roster = @steve.rosters.first
        roster.destroy
        get api_v1_roster_path(roster), headers: @headers
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET /api/v1/rosters (index)' do
      it 'loads the user\'s rosters' do
        get api_v1_rosters_path, headers: @headers
        expect(response).to have_http_status(:success)
        rosters = JSON.parse(response.body)
        expect(rosters.count).to eq(1)
        expect(rosters.first['name']).to eq(@steve.rosters.first.name)
      end
    end

    describe 'DELETE /destroy' do
      it 'returns http success and deleted the object' do
        toDelete = @steve.rosters.first
        delete api_v1_roster_path(toDelete), headers: @headers
        expect(response).to have_http_status(:success)
        expect(@steve.rosters.find_by(id: toDelete.id)).to be_nil
      end
    end
  end
end
