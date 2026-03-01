# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  let(:credentials) { { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "changeme") } }

  describe "GET /admin" do
    it "returns success with valid credentials" do
      get "/admin", headers: credentials

      expect(response).to have_http_status(:ok)
    end

    it "returns unauthorized without credentials" do
      get "/admin"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized with wrong credentials" do
      bad_creds = { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("wrong", "wrong") }

      get "/admin", headers: bad_creds

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
