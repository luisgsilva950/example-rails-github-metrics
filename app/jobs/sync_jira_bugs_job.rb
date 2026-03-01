# frozen_string_literal: true

class SyncJiraBugsJob < ApplicationJob
  SETTING_KEY = "jira_bugs"

  queue_as :default

  def perform
    setting = SyncSetting.for(SETTING_KEY)
    return unless setting.enabled?

    setting.mark_syncing!

    jql = JiraBugs::BuildIncrementalJql.new.call(last_synced_at: setting.last_synced_at)
    max_results = ENV.fetch("JIRA_MAX_RESULTS", "500").to_i

    Rails.logger.info "[SyncJiraBugsJob] Starting incremental sync. JQL: #{jql}"

    JiraBugsExtractor.new(client: JiraClient.new, jql: jql, max_results: max_results).call
    setting.mark_completed!

    Rails.logger.info "[SyncJiraBugsJob] Sync completed at #{setting.last_synced_at}"
  rescue StandardError => e
    SyncSetting.for(SETTING_KEY).mark_failed!(e.message)
    Rails.logger.error "[SyncJiraBugsJob] Sync failed: #{e.message}"
    raise
  end
end
