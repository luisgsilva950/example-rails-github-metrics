# frozen_string_literal: true

class Metrics::SyncSettingsController < ApplicationController
  def toggle
    setting = SyncSetting.for(params[:key])
    setting.update!(enabled: !setting.enabled?)

    SyncJiraBugsJob.perform_later if setting.enabled?

    redirect_to metrics_dashboard_path,
                notice: "JIRA sync #{setting.enabled? ? 'enabled' : 'disabled'}."
  end
end
