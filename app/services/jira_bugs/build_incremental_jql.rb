# frozen_string_literal: true

module JiraBugs
  # Builds JQL for incremental sync: tickets updated after the last sync date.
  # Uses `updated` instead of `created` so that status/category changes are captured.
  # Returns the JQL string used for extraction.
  class BuildIncrementalJql
    def call(last_synced_at:)
      date = format_date(last_synced_at)
      jql = 'project = CWS AND type = Bug AND "squad[dropdown]" IN ("Digital Farm")'
      jql += " AND updated >= '#{date}'" if date
      jql + " ORDER BY updated DESC"
    end

    private

    def format_date(time)
      return nil if time.nil?

      time.in_time_zone(JiraBug::SAO_PAULO_TZ).strftime("%Y-%m-%d")
    end
  end
end
