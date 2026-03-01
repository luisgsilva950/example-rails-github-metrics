# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Metrics::Dashboard", type: :request do
  describe "GET /metrics/dashboard" do
    it "shows idle status when never synced" do
      get "/metrics/dashboard"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Idle")
      expect(response.body).to include("Never synced")
    end

    it "shows completed status after successful sync" do
      create(:sync_setting, key: "jira_bugs", status: "completed", last_synced_at: 5.minutes.ago)

      get "/metrics/dashboard"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Completed")
    end

    it "shows failed status with error message" do
      create(:sync_setting, key: "jira_bugs", status: "failed", last_error: "Connection refused")

      get "/metrics/dashboard"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Failed")
      expect(response.body).to include("Sync error:")
      expect(response.body).to include("Connection refused")
    end

    it "shows syncing status when job is running" do
      create(:sync_setting, key: "jira_bugs", status: "syncing")

      get "/metrics/dashboard"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Syncing")
    end

    it "does not show error banner when status is not failed" do
      create(:sync_setting, key: "jira_bugs", status: "completed")

      get "/metrics/dashboard"

      expect(response.body).not_to include("Sync error:")
    end
  end
end
