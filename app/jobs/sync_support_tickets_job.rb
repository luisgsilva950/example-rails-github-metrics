# frozen_string_literal: true

class SyncSupportTicketsJob < ApplicationJob
  SETTING_KEY = "support_tickets"

  queue_as :default

  def perform
    setting = SyncSetting.for(SETTING_KEY)
    return unless setting.enabled?

    setting.mark_syncing!

    jql = SupportTickets::BuildIncrementalJql.new.call(last_synced_at: setting.last_synced_at)
    max_results = ENV.fetch("JIRA_MAX_RESULTS", "500").to_i

    Rails.logger.info "[SyncSupportTicketsJob] Starting incremental sync. JQL: #{jql}"

    SupportTicketsExtractor.new(client: JiraClient.new, jql: jql, max_results: max_results).call
    setting.mark_completed!

    Rails.logger.info "[SyncSupportTicketsJob] Sync completed at #{setting.last_synced_at}"
  rescue StandardError => e
    SyncSetting.for(SETTING_KEY).mark_failed!(e.message)
    Rails.logger.error "[SyncSupportTicketsJob] Sync failed: #{e.message}"
    raise
  end
end
