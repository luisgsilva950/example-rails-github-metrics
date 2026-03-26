# frozen_string_literal: true

class SyncSonarMetricsJob < ApplicationJob
  SETTING_KEY = "sonar_metrics"

  queue_as :default

  def perform
    setting = SyncSetting.for(SETTING_KEY)
    return unless setting.enabled?

    since = setting.last_synced_at
    setting.mark_syncing!

    Rails.logger.info "[SyncSonarMetricsJob] Starting sync (since: #{since || 'initial'})"

    sync_projects
    sync_metrics(since)
    sync_all_issues(since)

    setting.mark_completed!
    Rails.logger.info "[SyncSonarMetricsJob] Sync completed at #{setting.last_synced_at}"
  rescue StandardError => e
    SyncSetting.for(SETTING_KEY).mark_failed!(e.message)
    Rails.logger.error "[SyncSonarMetricsJob] Sync failed: #{e.message}"
    raise
  end

  private

  def sync_projects
    SyncSonarProjects.new.call
  end

  def sync_metrics(since)
    SyncSonarMetrics.new.call(since: since)
  end

  def sync_all_issues(since)
    SonarProject.find_each do |project|
      SyncSonarIssues.new.call(project: project, since: since)
    end
  end
end
