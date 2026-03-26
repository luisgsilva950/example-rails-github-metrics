# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncSonarMetricsJob do
  describe "#perform" do
    it "does nothing when sync is disabled" do
      create(:sync_setting, key: "sonar_metrics", enabled: false)

      expect(SyncSonarProjects).not_to receive(:new)

      described_class.new.perform
    end

    it "syncs projects, metrics, and issues when enabled" do
      setting = create(:sync_setting, key: "sonar_metrics", enabled: true)
      project = create(:sonar_project, sonar_key: "org_repo")

      sync_projects = instance_double(SyncSonarProjects, call: 1)
      sync_metrics = instance_double(SyncSonarMetrics, call: nil)
      sync_issues = instance_double(SyncSonarIssues)

      allow(SyncSonarProjects).to receive(:new).and_return(sync_projects)
      allow(SyncSonarMetrics).to receive(:new).and_return(sync_metrics)
      allow(SyncSonarIssues).to receive(:new).and_return(sync_issues)
      allow(sync_issues).to receive(:call).with(project: project, since: nil).and_return(0)

      described_class.new.perform

      setting.reload
      expect(setting.status).to eq("completed")
      expect(setting.last_synced_at).to be_within(2.seconds).of(Time.current)
      expect(setting.last_error).to be_nil
      expect(sync_metrics).to have_received(:call).with(since: nil)
    end

    it "passes last_synced_at as since to resume from previous sync" do
      last_sync = 3.hours.ago
      setting = create(:sync_setting, key: "sonar_metrics", enabled: true, last_synced_at: last_sync)
      create(:sonar_project, sonar_key: "project_a")
      create(:sonar_project, sonar_key: "project_b")

      sync_projects = instance_double(SyncSonarProjects, call: 2)
      sync_metrics = instance_double(SyncSonarMetrics, call: nil)
      sync_issues = instance_double(SyncSonarIssues)

      allow(SyncSonarProjects).to receive(:new).and_return(sync_projects)
      allow(SyncSonarMetrics).to receive(:new).and_return(sync_metrics)
      allow(SyncSonarIssues).to receive(:new).and_return(sync_issues)
      allow(sync_issues).to receive(:call).and_return(0)

      described_class.new.perform

      expect(sync_metrics).to have_received(:call).with(since: last_sync)
      expect(sync_issues).to have_received(:call).twice
      expect(sync_issues).to have_received(:call).with(hash_including(since: last_sync)).twice
    end

    it "marks failed and re-raises on error" do
      setting = create(:sync_setting, key: "sonar_metrics", enabled: true)

      sync_projects = instance_double(SyncSonarProjects)
      allow(SyncSonarProjects).to receive(:new).and_return(sync_projects)
      allow(sync_projects).to receive(:call).and_raise(StandardError, "API timeout")

      expect { described_class.new.perform }.to raise_error(StandardError, "API timeout")

      setting.reload
      expect(setting.status).to eq("failed")
      expect(setting.last_error).to eq("API timeout")
    end
  end
end
