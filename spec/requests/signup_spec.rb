
require 'rails_helper'

RSpec.describe 'POST api/v1/signup', type: :request do
  let(:url) { '/api/v1/signup' }
  let(:params) do
    {
      user: {
        email: 'user@example.com',
        password: 'password'
      }
    }
  end

  context 'when user is unauthenticated' do
    before { post url, params: params }

    it 'returns 200' do
      expect(response.status).to eq 200
    end

    xit 'returns a new user' do
      expect(response.body).to match_schema('user')
    end
  end

  context 'when user already exists' do
    before do
      User.create!(email: params[:user][:email], password: "321Passwd$$$", confirmed_at: DateTime.now)
      post url, params: params
    end

    it 'returns bad request status' do
      expect(response.status).to eq 400
    end

    xit 'returns validation errors' do
      expect(json['errors'].first['title']).to eq('Bad Request')
    end
  end
end