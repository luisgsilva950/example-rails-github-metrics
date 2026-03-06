# frozen_string_literal: true

module SupportTickets
  # Builds JQL for incremental sync of support tickets.
  # Uses `updated` instead of `created` so that status changes are captured.
  # Returns the JQL string used for extraction.
  class BuildIncrementalJql
    def call(last_synced_at:)
      date = format_date(last_synced_at)
      jql = 'project = CWS AND type = Support AND "squad[dropdown]" IN ("Digital Farm")'
      jql += " AND updated >= '#{date}'"
      jql + " ORDER BY updated DESC"
    end

    private

    def format_date(time)
      effective = time || 1.year.ago
      effective.in_time_zone(SupportTicket::SAO_PAULO_TZ).strftime("%Y-%m-%d")
    end
  end
end
