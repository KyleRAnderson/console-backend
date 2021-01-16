# frozen_string_literal: true

require 'rails_helper'
require 'support/fixture_file_upload' # FIXME remove when https://gitlab.com/hunt-console/console-backend/-/issues/1 is resolved.

RSpec::Matchers.define_negated_matcher :not_change, :change

TEMPLATE_PDF_FIXTURE_PATH = 'template_pdfs/allFields.pdf'

RSpec.describe 'Api::V1::Hunts::TemplatePdfs', type: :request do
  let(:user) { create(:user) }
  let(:user_permission) { build(:permission, level: :owner, user: user) }
  let(:roster) { create(:roster, permissions: [user_permission]) }
  let(:hunt) { create(:hunt, roster: roster) }

  include TemporaryFixes # FIXME remove when #1 is resolved.
  let(:template_pdf_upload) { fixture_file_upload(TEMPLATE_PDF_FIXTURE_PATH) }

  Permission.levels.keys.each do |level|
    context "with signed in user of level #{level}" do
      let(:user_permission) { build(:permission, level: level, user: user) }
      before(:each) { sign_in(user) }

      describe :create do
        shared_examples 'denies access' do
          it 'denies access with 403 forbidden', if: Permission.at_most?(level, :viewer) do
            expect { post api_v1_hunt_template_pdf_path(hunt), params: { template_pdf: template_pdf_upload } }
              .to(not_change { ActiveStorage::Attachment.count }.and(not_change { hunt.reload.template_pdf }))
            expect(response).to have_http_status(:forbidden)
          end
        end

        context 'with a valid template PDF file and no previous attachment' do
          include_examples 'denies access'

          it 'uploads successfully', if: Permission.at_least?(level, :operator) do
            expect do
              post api_v1_hunt_template_pdf_path(hunt), params: { template_pdf: template_pdf_upload }
              expect(response).to have_http_status(:success)
            end.to(change { ActiveStorage::Attachment.count }.by(1))
            expect(hunt.reload.template_pdf).to be_attached
          end
        end

        context 'with a valid template PDF file and a pre-existing attachment' do
          before(:each) do
            hunt.template_pdf.attach(io: file_fixture(TEMPLATE_PDF_FIXTURE_PATH).open, filename: 'template_pdf.pdf', content_type: 'application/pdf')
          end

          include_examples 'denies access'

          it 'replaces the current attachment with the newly uploaded one', if: Permission.at_least?(level, :operator) do
            expect do
              post api_v1_hunt_template_pdf_path(hunt), params: { template_pdf: template_pdf_upload }
              expect(response).to have_http_status(:success)
            end.to(change { ActiveStorage::Attachment.count }.by(0).and(change { hunt.reload.template_pdf.id }))
            expect(hunt.reload.template_pdf).to be_attached
          end
        end
      end

      describe :destroy do
        shared_examples 'denies access' do
          it 'denies access with 403 forbidden', if: Permission.at_most?(level, :viewer) do
            expect do
              delete api_v1_hunt_template_pdf_path(hunt)
              expect(response).to have_http_status(:forbidden)
            end.to(not_change { ActiveStorage::Attachment.count }.and(not_change { hunt.reload.template_pdf }))
          end
        end

        context 'with an existing template PDF' do
          before(:each) do
            hunt.template_pdf.attach(io: file_fixture(TEMPLATE_PDF_FIXTURE_PATH).open, filename: 'template_pdf.pdf', content_type: 'application/pdf')
          end

          include_examples 'denies access'

          it 'deletes the template PDF', if: Permission.at_least?(level, :operator) do
            expect(hunt.template_pdf).to be_attached # Ensure proper start state
            expect do
              delete api_v1_hunt_template_pdf_path(hunt)
              expect(response).to have_http_status(:success)
            end.to(change { ActiveStorage::Attachment.count }.by(-1))
            expect(hunt.reload.template_pdf).not_to be_attached
          end
        end

        context 'with no existing template pdf' do
          include_examples 'denies access'

          it 'does nothing', if: Permission.at_least?(level, :operator) do
            expect do
              delete api_v1_hunt_template_pdf_path(hunt)
              expect(response).to have_http_status(:success)
            end.not_to(change { ActiveStorage::Attachment.count })
            expect(hunt.template_pdf).not_to be_attached
          end
        end
      end
    end
  end

  context 'with no signed in user' do
    describe :create do
      it 'returns 401 unauthorized' do
        post api_v1_hunt_template_pdf_path(hunt), params: { template_pdf: template_pdf_upload }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe :destroy do
      it 'returns 401 unauthorized' do
        delete api_v1_hunt_template_pdf_path(hunt)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  context 'with wrong signed in user' do
    let(:incorrect_user) { create(:user) }
    before(:each) { sign_in(incorrect_user) }

    it 'returns 404 not found on the hunt' do
      expect do
        post api_v1_hunt_template_pdf_path(hunt), params: { template_pdf: template_pdf_upload }
        expect(response).to have_http_status(:not_found)
      end.not_to(change { ActiveStorage::Attachment.count })
      expect(hunt.reload.template_pdf).not_to be_attached
    end
  end
end
