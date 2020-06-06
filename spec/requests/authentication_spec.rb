# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Sessions', type: :request do
  let(:user) { create(:user) }
  let(:params) do
    {
      user: {
        email: user.email,
        password: user.password,
      },
    }
  end

  context 'when params are correct' do
    it 'successsfully logs in' do
      post user_session_path, params: params
      expect(response).to have_http_status(:success)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['email']).to eq(user.email)
      expect(parsed_response['id']).to eq(user.id)
    end
  end

  context 'when login params are incorrect' do
    context 'without including an email and password' do
      it 'returns unathorized status' do
        post user_session_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid email, but invalid password' do
      it 'returns unauthorized session' do
        params[:user][:password] = 'wrong_password'
        post user_session_path, params: params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'logout (DELETE)' do
    before(:each) { sign_in(user) }

    it 'returns 204, no content' do
      delete destroy_user_session_path
      expect(response).to have_http_status(:no_content)
    end
  end
end
