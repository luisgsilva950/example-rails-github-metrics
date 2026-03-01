class Metrics::DashboardController < ApplicationController
  def index
    @jira_sync = SyncSetting.for("jira_bugs")
  end
end
