require 'rails_helper'

RSpec.describe 'Api::V1::Licenses', type: :request do
  let(:user) { create(:user) }

  before(:each) { sign_in(user) }

  Permission.levels.keys.each do |level|
    context "with logged in #{level} user" do
      let(:user_permission) { build(:permission, level: level, user: user) }
      let(:roster) { create(:roster, permissions: [user_permission]) }
      let(:hunt) { create(:hunt, roster: roster) }
      let(:participant) { create(:participant, roster: roster) }
      let(:other_participant) { create(:participant, roster: roster) }
      let(:license) { create(:license, hunt: hunt, participant: participant) }

      describe 'get license (SHOW)' do
        it 'retrieves license information, containing participant info' do
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
        it 'succeeds and destroys the provided license', if: Permission.at_least?(level, :operator) do
          delete api_v1_license_path(license)
          expect(response).to have_http_status(:success)
          expect(License.exists?(license.id)).to be false
        end

        it 'denies access with 403 forbidden', if: Permission.at_most?(level, :viewer) do
          delete api_v1_license_path(license)
          expect(response).to have_http_status(:forbidden)
          expect(License.exists?(license.id)).to be true
        end
      end

      describe 'edit license (UPDATE)' do
        if Permission.at_least?(level, :operator)
          it 'allows updating the eliminated attribute' do
            expectation = expect do
              patch api_v1_license_path(license),
                params: { license: { eliminated: true } }
            end
            expectation.to change { license.reload.eliminated }.from(false).to(true)
            expect(JSON.parse(response.body)['eliminated']).to be true
            expect(response).to have_http_status(:success)
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

        it 'denies access with 403 forbidden', if: Permission.at_most?(level, :viewer) do
          patch api_v1_license_path(license),
                params: { license: { eliminated: true } }
          expect(response).to have_http_status(:forbidden)
          expect(license.reload.eliminated).to be false
        end
      end

      describe 'post license (CREATE)' do
        if Permission.at_least?(level, :operator)
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

        it 'denies access with 403 forbidden', if: Permission.at_most?(level, :viewer) do
          post api_v1_hunt_licenses_path(hunt),
               params: { license: { participant_id: other_participant.id } }
          expect(response).to have_http_status(:forbidden)
          expect(License.find_by(participant_id: other_participant.id)).to be_blank
        end
      end

      describe 'get licenses (INDEX)' do
        it 'gets all the licenses associated with the hunt' do
          expected_licenses = [true, false].reduce([]) { |total, value| total + create_list(:license, 25, hunt: hunt, eliminated: value) }
          received_ids = []
          (1..5).each do |i|
            get api_v1_hunt_licenses_path(hunt), params: { page: i, per_page: 10 }
            expect(response).to have_http_status(:success)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response).to have_key('licenses')
            expect(parsed_response).to have_key('num_pages')
            expect(parsed_response['num_pages']).to eq(5)
            parsed_licenses = parsed_response['licenses']
            expect(parsed_licenses.length).to eq(10)
            received_ids += parsed_licenses.map { |license| license['id'] }
          end
          expect(received_ids).to match_array(expected_licenses.map(&:id))
        end

        context 'with filter params provided' do
          let!(:licenses_by_eliminated) do
            [true, false].to_h { |value| [value, create_list(:license, 25, hunt: hunt, eliminated: value)] }
          end
          let(:all_licenses) { licenses_by_eliminated.values.flatten }

          describe 'on eliminated status' do
            [true, false].each do |eliminated|
              it "renders all licenses with eliminated: #{eliminated} in one page when per_page set to num licenses" do
                get api_v1_hunt_licenses_path(hunt), params: { page: 1, per_page: all_licenses.size,
                                                               eliminated: eliminated }
                expect(response).to have_http_status(:success)
                parsed_response = JSON.parse(response.body)
                expect(parsed_response['num_pages']).to eq(1)
                expect(parsed_response['licenses'].map { |license| license['id'] }).to match_array(licenses_by_eliminated[eliminated].map(&:id))
              end
            end
            [true, false].each do |eliminated|
              it "renders licenses paginated with eliminated filtered to #{eliminated}" do
                expected_licenses = licenses_by_eliminated[eliminated]
                per_page = (expected_licenses.size * 0.5).ceil
                received_ids = []
                (1..2).each do |page|
                  get api_v1_hunt_licenses_path(hunt), params: { page: page, per_page: per_page, eliminated: eliminated }
                  expect(response).to have_http_status(:success)
                  parsed_response = JSON.parse(response.body)
                  expect(parsed_response['num_pages']).to eq(2)
                  received_ids += parsed_response['licenses'].map { |license| license['id'] }
                end
                expect(received_ids).to match_array(expected_licenses.map(&:id))
              end
            end
          end
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
