require 'rails_helper'

RSpec.describe 'Api::V1::Licenses', type: :request do
  before(:all) do
    @user = create(:user)
    sign_in_user(@user)
  end
  after(:all) { @user.destroy! }

  describe 'with logged in user' do
    let(:roster) { create(:roster_with_participants_hunts, user: @user, num_hunts: 2, num_participants: 10) }
    let(:hunt) { create(:hunt_with_licenses_rounds, roster: roster) }
    let(:participant) { create(:participant, roster: roster) }
    let(:other_participant) { create(:participant, roster: roster) }
    let(:license) { create(:license, hunt: hunt, participant: participant) }

    describe 'show action' do
      it 'sucessfully completes the request and retrieves license information, containing participant info' do
        get api_v1_license_path(license), headers: @headers
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

    describe 'destroy action' do
      it 'succeeds and destroys the provided license' do
        delete api_v1_license_path(license), headers: @headers
        expect(response).to have_http_status(:success)
        expect(License.find_by(id: license.id)).to be_nil
      end
    end

    describe 'update action' do
      it 'allows updating the eliminated attribute' do
        patch api_v1_license_path(license),
          params: { license: { eliminated: true } },
          headers: @headers
        expect(response).to have_http_status(:success)
        expect(license.reload.eliminated).to be true
      end

      it 'does not allow update to other attributes' do
        patch api_v1_license_path(license),
          params: { license: { participant_id: other_participant.id, eliminated: true } },
          headers: @headers
        expect(response).to have_http_status(:bad_request)
        errors = JSON.parse(response.body)
        expect(errors).to have_key('detail')
        expect(errors['detail']).to have_key('license')
        expect(errors['detail']['license']).not_to be_empty
        expect(license.reload.eliminated).to be false
      end
    end

    describe 'create action' do
      it 'creates a license when provided valid arguments' do
        post api_v1_hunt_licenses_path(hunt),
             headers: @headers,
             params: { license: { participant_id: other_participant.id } }
        expect(response).to have_http_status(:created)
        parsed_license = JSON.parse(response.body)
        expect(parsed_license['eliminated']).to be false
        expect(parsed_license).to have_key('participant')
        expect(parsed_license['participant']['id']).to eq(other_participant.id)
      end

      it 'allows a license with eliminated to be created' do
        post api_v1_hunt_licenses_path(hunt),
             headers: @headers,
             params: { license: { eliminated: true, participant_id: other_participant.id } }
        expect(response).to have_http_status(:created)
        parsed_license = JSON.parse(response.body)
        expect(parsed_license['eliminated']).to be true
        expect(parsed_license).to have_key('participant')
        expect(parsed_license['participant']['id']).to eq(other_participant.id)
      end
    end

    describe 'index action' do
      it 'gets all the licenses associated with the hunt' do
        get api_v1_hunt_licenses_path(hunt), headers: @headers
        expect(response).to have_http_status(:success)
        parsed_licenses = JSON.parse(response.body)
        expect(parsed_licenses.length).to eq(hunt.licenses.length)
      end
    end
  end

  describe 'with incorrect logged in user' do
    let(:wrong_user_license) { create(:license) }

    describe 'show action' do
      it 'returns 404' do
        get api_v1_license_path(wrong_user_license.hunt, wrong_user_license), headers: @headers
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'destroy action' do
      it 'returns 404' do
        delete api_v1_license_path(wrong_user_license.hunt, wrong_user_license), headers: @headers
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'update action' do
      it 'returns 404' do
        patch api_v1_license_path(wrong_user_license.hunt, wrong_user_license),
          headers: @headers,
          params: { license: { eliminated: true } }
        expect(response).to have_http_status(:not_found)
        expect(wrong_user_license.reload.eliminated).to be false
      end
    end
  end
end
