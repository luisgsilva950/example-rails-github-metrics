# frozen_string_literal: true

module SupportTickets
  class CloneToBugs
    PROJECT_KEY = "CWS"
    TEAM_FIELD = "customfield_10265"

    # Required custom fields for Bug issue type on JIRA
    REQUIRED_BUG_FIELDS = {
      "customfield_10200" => "N/A", # Functionality
      "customfield_10201" => "N/A", # Flow
      "customfield_10202" => "N/A", # Expected Behaviour
      "customfield_10203" => "N/A"  # Problem
    }.freeze

    def initialize(client: JiraClient.new)
      @client = client
    end

    def call(ticket_ids:)
      tickets = SupportTicket.not_cloned.where(id: ticket_ids)

      tickets.map { |ticket| clone_ticket(ticket) }
    end

    private

    def clone_ticket(ticket)
      issue_key = @client.create_issue(fields: jira_fields(ticket))
      @client.link_issues(inward_key: issue_key, outward_key: ticket.issue_key)
      ticket.update!(cloned_to_bug_key: issue_key)
      save_local_bug(issue_key, ticket)
    end

    def jira_fields(ticket)
      fields = base_fields(ticket)
      fields["components"] = ticket.components.map { |c| { "name" => c } } if ticket.components.present?
      fields[TEAM_FIELD] = { "value" => ticket.team } if ticket.team.present?
      fields
    end

    def base_fields(ticket)
      {
        "project" => { "key" => PROJECT_KEY },
        "issuetype" => { "name" => "Bug" },
        "summary" => ticket.title,
        "description" => ticket.description.to_s,
        "priority" => { "name" => ticket.priority || "Medium" }
      }.merge(REQUIRED_BUG_FIELDS)
    end

    def save_local_bug(issue_key, ticket)
      JiraBug.find_or_initialize_by(issue_key: issue_key).tap do |bug|
        bug.assign_attributes(local_attributes(issue_key, ticket))
        bug.save!
      end
    end

    def local_attributes(issue_key, ticket)
      {
        issue_key: issue_key,
        title: ticket.title,
        description: ticket.description,
        priority: ticket.priority,
        team: ticket.team,
        assignee: ticket.assignee,
        reporter: ticket.reporter,
        components: ticket.components,
        opened_at: ticket.opened_at,
        jira_updated_at: ticket.jira_updated_at,
        status: ticket.status,
        categories: [],
        labels: [],
        issue_type: "Bug"
      }
    end
  end
end
