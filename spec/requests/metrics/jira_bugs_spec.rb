# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Metrics::JiraBugs", type: :request do
  let(:team) { "Digital Farm" }
  let(:today) { Time.current.in_time_zone(JiraBug::SAO_PAULO_TZ).to_date }

  before do
    create(:jira_bug, :with_categories, team: team, opened_at: today - 5.days, development_type: "Frontend", components: [ "CW Elements" ])
    create(:jira_bug, :with_feature, team: team, opened_at: today - 3.days, development_type: "Backend", components: [ "Weather" ])
    create(:jira_bug, :data_integrity, team: team, opened_at: today - 1.day, development_type: "Frontend", components: [ "Notes" ])
  end

  describe "GET /metrics/jira_bugs/unclassified" do
    it "returns JSON with unclassified bugs" do
      create(:jira_bug, team: team, development_type: nil, components: [])

      get "/metrics/jira_bugs/unclassified", params: { team: team }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key("content")
      expect(body).to have_key("meta")
    end
  end

  describe "GET /metrics/jira_bugs/by_category" do
    it "returns JSON with categories map" do
      get "/metrics/jira_bugs/by_category", params: { team: team }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key("content")
      expect(body["meta"]["team"]).to eq(team)
    end
  end

  describe "GET /metrics/jira_bugs/bubble_chart" do
    it "returns JSON with bubble chart data" do
      get "/metrics/jira_bugs/bubble_chart", params: { team: team }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key("data")
      expect(body).to have_key("labels")
    end
  end

  describe "GET /metrics/jira_bugs/bubble_chart_page" do
    it "renders the bubble chart page" do
      get "/metrics/jira_bugs/bubble_chart_page", params: {
        team: team,
        start_date: (today - 30.days).iso8601,
        end_date: today.iso8601
      }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /metrics/jira_bugs/invalid_categories" do
    it "returns JSON with invalid categories" do
      get "/metrics/jira_bugs/invalid_categories", params: { team: team, page: 1, size: 10 }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to have_key("content")
      expect(body["meta"]).to include("page" => 1, "size" => 10)
    end
  end

  describe "GET /metrics/jira_bugs/invalid_categories_page" do
    it "renders the invalid categories page" do
      get "/metrics/jira_bugs/invalid_categories_page", params: {
        team: team,
        start_date: (today - 30.days).iso8601,
        end_date: today.iso8601
      }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /metrics/jira_bugs/all" do
    it "renders the all bugs page" do
      get "/metrics/jira_bugs/all", params: {
        team: team,
        start_date: (today - 30.days).iso8601,
        end_date: today.iso8601
      }

      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      get "/metrics/jira_bugs/all", params: {
        team: team,
        start_date: (today - 30.days).iso8601,
        end_date: today.iso8601,
        status: "10 Done"
      }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /metrics/jira_bugs/bugs_over_time" do
    it "renders the bugs over time page" do
      get "/metrics/jira_bugs/bugs_over_time", params: {
        team: team,
        start_date: (today - 30.days).iso8601,
        end_date: today.iso8601,
        group_by: "weekly"
      }

      expect(response).to have_http_status(:ok)
    end

    it "supports monthly grouping" do
      get "/metrics/jira_bugs/bugs_over_time", params: {
        team: team,
        start_date: (today - 90.days).iso8601,
        end_date: today.iso8601,
        group_by: "monthly"
      }

      expect(response).to have_http_status(:ok)
    end

    it "supports category filter" do
      get "/metrics/jira_bugs/bugs_over_time", params: {
        team: team,
        start_date: (today - 30.days).iso8601,
        end_date: today.iso8601,
        group_by: "weekly",
        category_filter: "feature"
      }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /metrics/jira_bugs/sync_from_jira" do
    it "redirects with alert on failure" do
      # No real JIRA client available in tests, expects failure
      post "/metrics/jira_bugs/sync_from_jira", params: {
        team: team,
        start_date: (today - 30.days).iso8601,
        end_date: today.iso8601
      }

      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end
  end
end
