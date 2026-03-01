# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Records", type: :request do
  let(:credentials) { { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "changeme") } }

  describe "GET /admin/records/jira_bugs" do
    it "returns success with records listed" do
      create(:jira_bug, title: "Test bug")

      get "/admin/records/jira_bugs", headers: credentials

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Test bug")
    end

    it "filters by name when q param provided" do
      create(:jira_bug, title: "Alpha bug")
      create(:jira_bug, title: "Beta bug")

      get "/admin/records/jira_bugs", params: { q: "Alpha" }, headers: credentials

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/records/commits" do
    it "returns success with commits listed" do
      repo = create(:repository)
      create(:commit, repository: repo, author_name: "Jane Doe")

      get "/admin/records/commits", headers: credentials

      expect(response).to have_http_status(:ok)
    end

    it "filters by normalized_author_names" do
      repo = create(:repository)
      create(:commit, repository: repo, author_name: "Jane Doe")
      create(:commit, repository: repo, author_name: "John Smith")

      get "/admin/records/commits", params: { normalized_author_names: ["jane doe"] }, headers: credentials

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/records/repositories" do
    it "returns success" do
      create(:repository)

      get "/admin/records/repositories", headers: credentials

      expect(response).to have_http_status(:ok)
    end

    it "filters repositories by name" do
      create(:repository, name: "org/my-repo")

      get "/admin/records/repositories", params: { q: "my-repo" }, headers: credentials

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/records/pull_requests" do
    it "returns success" do
      create(:pull_request)

      get "/admin/records/pull_requests", headers: credentials

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/records/:model/:id" do
    it "shows a single jira_bug record" do
      bug = create(:jira_bug)

      get "/admin/records/jira_bugs/#{bug.id}", headers: credentials

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(bug.issue_key)
    end

    it "shows a single commit record" do
      commit = create(:commit)

      get "/admin/records/commits/#{commit.id}", headers: credentials

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/records/unknown_model" do
    it "returns 404 for unknown model" do
      get "/admin/records/nonexistent", headers: credentials

      expect(response).to have_http_status(:not_found)
    end
  end
end
