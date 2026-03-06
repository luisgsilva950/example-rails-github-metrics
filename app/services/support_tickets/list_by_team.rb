# frozen_string_literal: true

module SupportTickets
  # Lists support tickets ordered by most recent, with team and date filtering.
  # Returns a hash with :tickets array and :total count.
  class ListByTeam
    def initialize(jira_base_url:)
      @jira_base_url = jira_base_url
    end

    def call(scope:, filters: {})
      scope = apply_filters(scope, filters)

      tickets = scope.most_recent
                     .select(*selected_fields)
                     .map { |ticket| serialize(ticket) }

      { tickets: tickets, total: tickets.size }
    end

    private

    def selected_fields
      %i[id issue_key title status priority team assignee reporter components opened_at cloned_to_bug_key]
    end

    def apply_filters(scope, filters)
      scope = scope.by_status(filters[:status]) if filters[:status].present?
      scope = scope.by_priority(filters[:priority]) if filters[:priority].present?
      scope
    end

    def serialize(ticket)
      {
        id: ticket.id,
        issue_key: ticket.issue_key,
        title: ticket.title,
        jira_link: "#{@jira_base_url}/browse/#{ticket.issue_key}",
        status: ticket.status,
        priority: ticket.priority,
        team: ticket.team,
        assignee: ticket.assignee,
        reporter: ticket.reporter,
        components: Array(ticket.components),
        opened_at: ticket.opened_at,
        cloned_to_bug_key: ticket.cloned_to_bug_key
      }
    end
  end
end
