# frozen_string_literal: true

class Metrics::SyncSettingsController < ApplicationController
  SYNC_JOBS = {
    "jira_bugs" => SyncJiraBugsJob,
    "support_tickets" => SyncSupportTicketsJob
  }.freeze

  def toggle
    setting = SyncSetting.for(params[:key])
    setting.update!(enabled: !setting.enabled?)

    SYNC_JOBS[params[:key]]&.perform_later if setting.enabled?

    redirect_to metrics_dashboard_path,
                notice: "Sync #{setting.enabled? ? 'enabled' : 'disabled'}."
  end
end
