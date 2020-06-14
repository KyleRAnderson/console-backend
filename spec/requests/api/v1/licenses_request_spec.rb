require 'rails_helper'

RSpec.describe 'Api::V1::Licenses', type: :request do
  before(:all) do
    @user = create(:user_with_rosters)
  end
  after(:all) { @user.destroy! }

  before(:each) { sign_in(@user) }

  describe 'with logged in user' do
    let(:roster) { create(:roster_with_participants_hunts, user: @user, num_hunts: 2, num_participants: 10) }
    let(:hunt) { create(:hunt_with_licenses_rounds, roster: roster) }
    let(:participant) { create(:participant, roster: roster) }
    let(:other_participant) { create(:participant, roster: roster) }
    let(:license) { create(:license, hunt: hunt, participant: participant) }

    describe 'get license (SHOW)' do
      it 'sucessfully completes the request and retrieves license information, containing participant info' do
        get api_v1_license_path(license)
        expect(response).to have_http_status(:success)
        decoded_license = JSON.parse(response.body)
        expect(decoded_license).to have_key('eliminated')
        expect(decoded_license['eliminated']).to be false # Should be false by default
        expect(decoded_license['id']).to eq(license.id)
        expect(decoded_license).to have_key('participant')
        expect(decoded_license['participant']).to have_key('first')
        expect(decoded_license['participant']).to have_key('last')
        expect(decoded_license['participant']).to have_key('extras')
        expect(decoded_license['participant']).to have_key('id')
        expect(decoded_license['participant']).not_to have_key('created_at')
        expect(decoded_license['participant']).not_to have_key('updated_at')
        roster.participant_properties.each do |property|
          expect(decoded_license['participant']['extras']).to have_key(property)
        end
      end
    end

    describe 'delete license (DESTROY)' do
      it 'succeeds and destroys the provided license' do
        delete api_v1_license_path(license)
        expect(response).to have_http_status(:success)
        expect(license).to be_destroyed
      end
    end

    describe 'edit license (UPDATE)' do
      it 'allows updating the eliminated attribute' do
        patch api_v1_license_path(license),
          params: { license: { eliminated: true } }
        expect(response).to have_http_status(:success)
        expect(license.reload.eliminated).to be true
      end

      it 'does not allow update to other attributes' do
        patch api_v1_license_path(license),
          params: { license: { participant_id: other_participant.id, eliminated: true } }
        expect(response).to have_http_status(:bad_request)
        errors = JSON.parse(response.body)
        expect(errors).to have_key('detail')
        expect(errors['detail']).to have_key('license')
        expect(errors['detail']['license']).not_to be_empty
        expect(license.reload.eliminated).to be false
      end
    end

    describe 'post license (CREATE)' do
      it 'creates a license when provided valid arguments' do
        post api_v1_hunt_licenses_path(hunt),
             params: { license: { participant_id: other_participant.id } }
        expect(response).to have_http_status(:created)
        parsed_license = JSON.parse(response.body)
        expect(parsed_license['eliminated']).to be false
        expect(parsed_license).to have_key('participant')
        expect(parsed_license['participant']['id']).to eq(other_participant.id)
      end

      it 'allows a license with eliminated to be created' do
        post api_v1_hunt_licenses_path(hunt),
             params: { license: { eliminated: true, participant_id: other_participant.id } }
        expect(response).to have_http_status(:created)
        parsed_license = JSON.parse(response.body)
        expect(parsed_license['eliminated']).to be true
        expect(parsed_license).to have_key('participant')
        expect(parsed_license['participant']['id']).to eq(other_participant.id)
      end
    end

    describe 'get licenses (INDEX)' do
      let(:roster_50_participants) { create(:roster_with_participants_hunts, num_hunts: 0, num_participants: 50, user: @user) }
      let(:hunt_50_licenses) { create(:hunt_with_licenses_rounds, roster: roster_50_participants, num_rounds: 0) }

      it 'gets all the licenses associated with the hunt' do
        previous_licenses = nil
        (1..5).each do |i|
          get api_v1_hunt_licenses_path(hunt_50_licenses), params: { page: i, per_page: 10 }
          expect(response).to have_http_status(:success)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to have_key('licenses')
          expect(parsed_response).to have_key('num_pages')
          expect(parsed_response['num_pages']).to eq(5)
          parsed_licenses = parsed_response['licenses']
          expect(parsed_licenses.length).to eq(10)
          expect(parsed_licenses).not_to eq(previous_licenses)
          previous_licenses = parsed_licenses
        end
      end
    end
  end

  describe 'with incorrect logged in user' do
    let(:wrong_user_license) { create(:license) }

    describe 'show action' do
      it 'returns 404' do
        get api_v1_license_path(wrong_user_license.hunt, wrong_user_license)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'destroy action' do
      it 'returns 404' do
        delete api_v1_license_path(wrong_user_license.hunt, wrong_user_license)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'update action' do
      it 'returns 404' do
        patch api_v1_license_path(wrong_user_license.hunt, wrong_user_license),
          params: { license: { eliminated: true } }
        expect(response).to have_http_status(:not_found)
        expect(wrong_user_license.reload.eliminated).to be false
      end
    end
  end
end
