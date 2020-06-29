require 'rails_helper'

USER_PASSWORD = 'password'.freeze

RSpec.describe 'create user (POST)', type: :request do
  let(:params) do
    {
      user: {
        email: 'user@example.com',
        password: USER_PASSWORD,
      },
    }
  end

  context 'when user is unauthenticated' do
    before { post user_registration_path, params: params }

    it 'returns created status' do
      expect(response).to have_http_status(:created)
    end

    it 'returns an unconfirmed new user' do
      user = JSON.parse(response.body)
      expect(user['email']).to eq(params[:user][:email])
      expect(user['id']).not_to be_blank
    end
  end

  context 'when user already exists' do
    before do
      User.create!(email: params[:user][:email], password: USER_PASSWORD, confirmed_at: DateTime.now)
      post user_registration_path, params: params
    end

    it 'returns user error request status' do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns validation errors' do
      errors = JSON.parse(response.body)
      expect(errors['errors']['email']).not_to be_blank
    end
  end
end
