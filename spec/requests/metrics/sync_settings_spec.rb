# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Metrics::SyncSettings", type: :request do
  describe "POST /metrics/sync_settings/toggle" do
    it "enables sync when currently disabled" do
      create(:sync_setting, key: "jira_bugs", enabled: false)

      post "/metrics/sync_settings/toggle", params: { key: "jira_bugs" }

      expect(response).to redirect_to(metrics_dashboard_path)
      expect(SyncSetting.find_by(key: "jira_bugs")).to be_enabled
    end

    it "enqueues sync job when enabling" do
      create(:sync_setting, key: "jira_bugs", enabled: false)

      expect {
        post "/metrics/sync_settings/toggle", params: { key: "jira_bugs" }
      }.to have_enqueued_job(SyncJiraBugsJob)
    end

    it "disables sync when currently enabled" do
      create(:sync_setting, key: "jira_bugs", enabled: true)

      post "/metrics/sync_settings/toggle", params: { key: "jira_bugs" }

      expect(response).to redirect_to(metrics_dashboard_path)
      expect(SyncSetting.find_by(key: "jira_bugs")).not_to be_enabled
    end

    it "does not enqueue sync job when disabling" do
      create(:sync_setting, key: "jira_bugs", enabled: true)

      expect {
        post "/metrics/sync_settings/toggle", params: { key: "jira_bugs" }
      }.not_to have_enqueued_job(SyncJiraBugsJob)
    end

    it "creates setting if it does not exist" do
      post "/metrics/sync_settings/toggle", params: { key: "jira_bugs" }

      expect(response).to redirect_to(metrics_dashboard_path)
      expect(SyncSetting.find_by(key: "jira_bugs")).to be_enabled
    end

    it "toggles support_tickets sync on" do
      create(:sync_setting, key: "support_tickets", enabled: false)

      post "/metrics/sync_settings/toggle", params: { key: "support_tickets" }

      expect(response).to redirect_to(metrics_dashboard_path)
      expect(SyncSetting.find_by(key: "support_tickets")).to be_enabled
    end

    it "enqueues support tickets sync job when enabling" do
      create(:sync_setting, key: "support_tickets", enabled: false)

      expect {
        post "/metrics/sync_settings/toggle", params: { key: "support_tickets" }
      }.to have_enqueued_job(SyncSupportTicketsJob)
    end
  end
end
