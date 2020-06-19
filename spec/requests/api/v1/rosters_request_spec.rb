require 'rails_helper'

RSpec.describe 'Api::V1::Rosters', type: :request do
  context 'with logged in user' do
    before(:all) do
      @steve = create(:user)
      create(:full_roster, num_participant_properties: 3, user: @steve)
    end
    after(:all) { @steve.destroy! }

    before(:each) do
      # Would like to know one day why the reload is necessary, other tests don't have it.
      @steve.reload
      sign_in(@steve)
    end

    describe 'POST /api/v1/rosters' do
      context 'with no participant properties' do
        it 'creates a new roster, with correct properties' do
          e = expect do
            post api_v1_rosters_path,
                 params: { roster: { name: 'Test roster 1' } }
          end
          e.to change { Roster.count }.by(1)
          expect(response).to have_http_status(:created)
          roster = JSON.parse(response.body)
          expect(roster['id']).not_to be_empty
          expect(roster['name']).to eq('Test roster 1')
          expect(roster['participant_properties']).to be_empty
        end
      end

      context 'with empty string participant properties' do
        it 'responds with an error' do
          e = expect do
            post api_v1_rosters_path,
                 params: {
                   roster: {
                     name: 'Testing rosters',
                     participant_properties: ['something', ''],
                   },
                 }
          end
          e.not_to(change { Roster.count })
          expect(response).to have_http_status(:bad_request)
        end
      end

      describe 'with participant properties' do
        it 'creates a new roster, with correct properties' do
          e = expect do
            post api_v1_rosters_path,
                 params: { roster: { name: 'Test roster 2',
                                    participant_properties: ['one', 'two', 'three'] } }
          end
          e.to change { Roster.count }.by(1)
          expect(response).to have_http_status(:created)

          roster = JSON.parse(response.body)
          expect(roster['id']).not_to be_empty
          expect(roster['name']).to eq('Test roster 2')
          expect(roster['participant_properties'].count).to eq(3)
          expect(roster['participant_properties'][0]).to eq('one')
          expect(roster['participant_properties'][1]).to eq('two')
          expect(roster['participant_properties'][2]).to eq('three')
        end
      end
    end

    describe 'GET api/v1/rosters/[roster_id] (show)' do
      it 'loads the roster with the given id successfully' do
        get api_v1_roster_path(@steve.rosters.first)
        expect(response).to have_http_status(:success)
        roster = JSON.parse(response.body)
        expect(roster['name']).to eq(@steve.rosters.first.name)
        expect(roster['participant_properties'].count).to eq(3)
      end

      it 'returns 404 not found upon providing an inexistent roster id' do
        roster = @steve.rosters.first
        roster.destroy
        get api_v1_roster_path(roster)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET /api/v1/rosters (index)' do
      it 'loads the user\'s rosters' do
        get api_v1_rosters_path
        expect(response).to have_http_status(:success)
        rosters = JSON.parse(response.body)
        expect(rosters.count).to eq(1)
        expect(rosters.first['name']).to eq(@steve.rosters.first.name)
      end
    end

    describe 'DELETE /destroy' do
      it 'returns http success and deletes the object' do
        to_delete = @steve.rosters.first
        delete api_v1_roster_path(to_delete)
        expect(response).to have_http_status(:success)
        expect(Roster.exists?(to_delete.id)).to be false
      end
    end
  end
end
