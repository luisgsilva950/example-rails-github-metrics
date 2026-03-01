# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Analytics", type: :request do
  let(:credentials) { { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "changeme") } }

  let!(:repo) { create(:repository, language: "Ruby") }

  before do
    # Create PRs spanning 2025 for overview metrics
    create(:pull_request, repository: repo, author_name: "Jane Doe",
           opened_at: Time.zone.local(2025, 3, 1), merged_at: Time.zone.local(2025, 3, 2),
           additions: 100, deletions: 20, changed_files: 5)
    create(:pull_request, repository: repo, author_name: "John Smith",
           opened_at: Time.zone.local(2025, 6, 1), merged_at: Time.zone.local(2025, 6, 3),
           additions: 200, deletions: 50, changed_files: 10)

    # Create commits for overview
    create(:commit, repository: repo, author_name: "Jane Doe",
           committed_at: Time.zone.local(2025, 3, 1, 6, 30))
    create(:commit, repository: repo, author_name: "John Smith",
           committed_at: Time.zone.local(2025, 6, 1, 23, 30))

    # Create JIRA bugs for jira_bugs and resolved tabs
    create(:jira_bug, team: "Digital Farm", priority: "High", status: "10 Done",
           components: [ "Weather" ], opened_at: 2.months.ago, assignee: "jane.doe")
    create(:jira_bug, team: "DA Backbone", priority: "Medium", status: "10 Done",
           components: [ "Notes" ], opened_at: 1.month.ago, assignee: "john.smith")
  end

  describe "GET /admin/analytics (default overview tab)" do
    it "returns success" do
      get "/admin/analytics", headers: credentials

      expect(response).to have_http_status(:ok)
    end

    it "loads overview metrics" do
      get "/admin/analytics", params: { tab: "overview" }, headers: credentials

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Year in review")
    end

    it "filters overview by author names" do
      get "/admin/analytics", params: { tab: "overview", overview_author_names: [ "jane doe" ] }, headers: credentials

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/analytics?tab=authors" do
    it "returns success with author metrics" do
      get "/admin/analytics", params: { tab: "authors" }, headers: credentials

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Author insights")
    end

    it "filters by author names" do
      get "/admin/analytics", params: {
        tab: "authors",
        normalized_author_names: [ "jane doe" ]
      }, headers: credentials

      expect(response).to have_http_status(:ok)
    end

    it "filters by opened_after date" do
      get "/admin/analytics", params: {
        tab: "authors",
        author_opened_from: "2025-01-01"
      }, headers: credentials

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/analytics?tab=repositories" do
    it "returns success with repository metrics" do
      get "/admin/analytics", params: { tab: "repositories" }, headers: credentials

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Repository insights")
    end

    it "filters by repository names" do
      get "/admin/analytics", params: {
        tab: "repositories",
        repository_names: [ repo.name ]
      }, headers: credentials

      expect(response).to have_http_status(:ok)
    end

    it "filters by opened_after date" do
      get "/admin/analytics", params: {
        tab: "repositories",
        repository_opened_from: "2025-01-01"
      }, headers: credentials

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/analytics?tab=jira_bugs" do
    it "returns success with jira metrics" do
      get "/admin/analytics", params: { tab: "jira_bugs" }, headers: credentials

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jira bug analytics")
    end

    it "filters by team" do
      get "/admin/analytics", params: {
        tab: "jira_bugs",
        jira_team_names: [ "Digital Farm" ]
      }, headers: credentials

      expect(response).to have_http_status(:ok)
    end

    it "filters by opened_from date" do
      get "/admin/analytics", params: {
        tab: "jira_bugs",
        jira_opened_from: 3.months.ago.to_date.iso8601
      }, headers: credentials

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/analytics?tab=resolved_bugs" do
    it "returns success with resolved bug metrics" do
      get "/admin/analytics", params: { tab: "resolved_bugs" }, headers: credentials

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bug resolution leaders")
    end

    it "filters by resolved teams" do
      get "/admin/analytics", params: {
        tab: "resolved_bugs",
        resolved_team_names: [ "DA Backbone" ]
      }, headers: credentials

      expect(response).to have_http_status(:ok)
    end

    it "filters by resolved opened_from" do
      get "/admin/analytics", params: {
        tab: "resolved_bugs",
        resolved_opened_from: 6.months.ago.to_date.iso8601
      }, headers: credentials

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/analytics?tab=retrospective" do
    it "loads all metrics at once" do
      get "/admin/analytics", params: { tab: "retrospective" }, headers: credentials

      expect(response).to have_http_status(:ok)
    end
  end

  describe "invalid tab parameter" do
    it "defaults to overview" do
      get "/admin/analytics", params: { tab: "nonexistent" }, headers: credentials

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Year in review")
    end
  end

  describe "invalid date parameter" do
    it "handles invalid date gracefully" do
      get "/admin/analytics", params: {
        tab: "authors",
        author_opened_from: "not-a-date"
      }, headers: credentials

      expect(response).to have_http_status(:ok)
    end
  end
end
