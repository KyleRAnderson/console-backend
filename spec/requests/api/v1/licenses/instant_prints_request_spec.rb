require 'rails_helper'

RSpec.describe 'Api::V1::Licenses::InstantPrints', type: :request do
  Permission.levels.keys.each do |level|
    context "with signed in user of level #{level}" do
      let(:user) { create(:user) }
      let(:user_permission) { build(:permission, level: level, user: user) }
      let(:participant_properties) do
        properties = 5.times.map { Faker::Space.unique.galaxy }
        Faker::Space.unique.clear
        properties
      end
      let(:roster) { create(:roster, permissions: [user_permission], participant_properties: participant_properties) }
      let(:hunt) { create(:hunt, roster: roster) }
      let(:template_pdf) { file_fixture('template_pdfs/allFields.pdf') }

      describe :create, skip_round: false, no_template: false do
        let(:params) { {} }

        before(:each) do
          sign_in(user)
        end

        before(:each, skip_round: false) { create(:round, hunt: hunt) }
        before(:each, no_template: false) do
          hunt.template_pdf.attach(io: template_pdf.open, filename: 'template_pdf.pdf', content_type: 'application/json')
        end

        shared_examples 'denies access' do
          it 'denies action with 403 forbidden', if: Permission.at_most?(level, :viewer) do
            expect do
              post api_v1_hunt_licenses_instant_prints_path(hunt), params: params, as: :json
              expect(response).to have_http_status(:forbidden)
            end.not_to have_enqueued_job
          end
        end

        shared_examples 'bad request' do |error_message|
          def additional_verification(body); end

          it 'fails with bad request', if: Permission.at_least?(level, :operator) do
            expect do
              post api_v1_hunt_licenses_instant_prints_path(hunt), params: params, as: :json
              expect(response).to have_http_status(:bad_request)
              expect(response.body).to include(error_message)
              additional_verification(response.body)
            end.not_to have_enqueued_job
          end
        end

        shared_examples 'suite' do |message = nil|
          include_examples 'denies access'
          include_examples 'bad request', message
        end

        context 'with no round', skip_round: true do
          include_examples 'suite', InstantPrintJob::INVALID_PROVIDED_ROUND_MESSAGE
        end

        context 'with no template PDF set on the hunt', no_template: true do
          include_examples 'suite', InstantPrintJob::NO_CONFIGURED_TEMPLATE_PDF_MESSAGE
        end

        context 'with invalid orderings' do
          describe 'where there are duplicate property entries' do
            let(:params) { { orderings: [[participant_properties[0], 'asc'], [participant_properties[1], 'desc'], [participant_properties[0], 'desc']] } }
            include_examples 'suite', InstantPrintJob::DUPLICATE_PROVIDED_PROPERTIES_MESSAGE do
              def additional_verification(body)
                expect(body).to include(participant_properties[0])
              end
            end
          end

          describe 'of wrong array sizes' do
            let(:params) { { orderings: [[participant_properties[0], 'asc', nil], [participant_properties[1]], [participant_properties[3], 'desc', 'yes', 'nie']] } }
            include_examples 'suite', InstantPrintJob::INVALID_ORDERING_PARAMS_LENGTH_MESSAGE
          end

          describe 'containing nonexistent properties' do
            let(:params) { { orderings: [[participant_properties[0], 'asc'], ['noexist', 'desc'], ['fake', 'asc'], [participant_properties[0], 'desc']] } }
            include_examples 'suite', InstantPrintJob::NONEXISTENT_PROPERTIES_MESSAGE do
              def additional_verification(body)
                expect(body).to include('fake', 'noexist')
              end
            end
          end

          describe 'with invalid orders (non desc or asc)' do
            let(:params) { { orderings: [[participant_properties[0], 'asc'], [participant_properties[1], 'dee'], [participant_properties[0], 'desc']] } }
            include_examples 'suite', InstantPrintJob::INVALID_ORDERS_MESSAGE
          end
        end

        context 'with a template PDF set and valid arguments' do
          shared_examples 'valid case' do
            include_examples 'denies access'
            let(:message) { nil }
            let(:orderings) { nil }

            it 'kicks off the instant print job with proper params', if: Permission.at_least?(level, :operator) do
              post api_v1_hunt_licenses_instant_prints_path(hunt), params: params, as: :json
              expect(response).to have_http_status(:accepted)
              expect(InstantPrintJob).to have_been_enqueued.with(hunt, orderings, message)
            end
          end

          describe 'with no orderings set' do
            include_examples 'valid case'
          end

          describe 'with all properties being ordered' do
            let(:orderings) { participant_properties.map { |property| [property, %w[asc desc].sample] } }
            let(:params) { { orderings: orderings } }
            include_examples 'valid case'
          end

          context 'with a message and no orderings set' do
            include_examples 'valid case' do
              let(:message) { 'Testing messages' }
              let(:params) { { message: message } }
            end
          end

          context 'with a message and orderings set' do
            include_examples 'valid case' do
              let(:orderings) { participant_properties.map { |property| [property, %w[asc desc].sample] } }
              let(:message) { 'Testing messages' }
              let(:params) { { message: message, orderings: orderings } }
            end
          end
        end
      end
    end
  end
end
