class Metrics::DashboardController < ApplicationController
  def index
    @jira_sync = SyncSetting.for("jira_bugs")
    @support_tickets_sync = SyncSetting.for("support_tickets")
  end
end
