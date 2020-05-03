require 'rails_helper'

RSpec.describe 'Api::V1::Rosters', type: :request do
  describe 'with logged in user' do
    fixtures :users, :rosters

    before(:each) do
      @steve = users(:steve)
      post '/api/v1/login', params: {
                              user: {
                                email: @steve.email,
                                password: '321Passwd$$$',
                              },
                            }
      token = response.headers['Authorization']
      @headers = { 'Authorization': token }
    end

    describe 'POST /api/v1/rosters' do
      describe 'with no participant properties' do
        it 'creates a new roster, with correct properties' do
          post '/api/v1/rosters', headers: @headers,
                                  params: { roster: { name: 'Test roster 1' } }
          expect(response).to have_http_status(:created)
          roster = JSON.parse(response.body)
          expect(roster['id']).not_to be_empty
          expect(roster['name']).to eq('Test roster 1')
          expect(roster['user_id']).to eq(@steve.id)
          expect(roster['participant_properties']).to be_empty
        end
      end

      describe 'with participant properties' do
        it 'creates a new roster, with correct properties' do
          post '/api/v1/rosters', headers: @headers,
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

    describe 'GET api/v1/rosters/[roster_id]' do
      it 'loads the roster with the given id successfully' do
        get "/api/v1/rosters/#{@steve.rosters.first.id}", headers: @headers
        expect(response).to have_http_status(:success)
      end
    end

    describe 'GET /api/v1/rosters' do
      it 'loads the user\'s rosters' do
        get '/api/v1/rosters', headers: @headers
        expect(response).to have_http_status(:success)
        rosters = JSON.parse(response.body)
        expect(rosters.count).to eq(1)
      end
    end

    describe 'DELETE /destroy' do
      it 'returns http success' do
        delete "/api/v1/rosters/#{@steve.rosters.first.id}", headers: @headers
        expect(response).to have_http_status(:success)
      end
    end
  end
end
