require 'rails_helper'

RSpec.describe 'POST api/v1/signup', type: :request do
  let(:url) { '/api/v1/signup' }
  let(:params) do
    {
      user: {
        email: 'user@example.com',
        password: 'password',
      },
    }
  end

  context 'when user is unauthenticated' do
    before { post url, params: params }

    it 'returns 200' do
      expect(response.status).to eq 200
    end

    it 'returns an unconfirmed new user' do
      user = JSON.parse(response.body)
      expect(user['email']).to eq(params[:user][:email])
      expect(user['id']).not_to be_empty
    end
  end

  context 'when user already exists' do
    before do
      User.create!(email: params[:user][:email], password: '321Passwd$$$', confirmed_at: DateTime.now)
      post url, params: params
    end

    it 'returns bad request status' do
      expect(response.status).to eq 400
    end

    it 'returns validation errors' do
      errors = JSON.parse(response.body)
      expect(errors['errors'].first['status']).to eq('400')
      expect(errors['errors'].first['title']).to eq('Bad Request')
    end
  end
end
