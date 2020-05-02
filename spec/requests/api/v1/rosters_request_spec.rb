require 'rails_helper'

RSpec.describe "Api::V1::Rosters", type: :request do

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/rosters/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/rosters/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/rosters/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/rosters/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
