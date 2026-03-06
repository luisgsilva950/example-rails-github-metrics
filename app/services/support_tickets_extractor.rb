# frozen_string_literal: true

# Extracts support tickets from JIRA and persists them locally.
# Receives a JiraClient and JQL, fetches issues and upserts SupportTicket records.
class SupportTicketsExtractor
  def initialize(client:, jql:, max_results: 500)
    @client = client
    @jql = jql
    @max_results = max_results
  end

  def call
    Rails.logger.info "[SupportTicketsExtractor] Starting extraction. JQL: #{@jql}"
    issues = @client.search_issues(@jql, max_results: @max_results)
    Rails.logger.info "[SupportTicketsExtractor] Total issues returned: #{issues.size}"

    issues.each { |issue| save_issue(issue) }
  end

  private

  PRIORITY_FIELD = "priority"
  TEAM_FIELD_PRIMARY = "customfield_10265"
  TEAM_FIELD_FALLBACK = "customfield_10300"
  REPORTER_FIELD = "reporter"
  STATUS_FIELD = "status"
  RESPONSIBLE_FIELD = "assignee"
  TITLE_FIELD = "summary"
  CREATED_FIELD = "created"
  UPDATED_FIELD = "updated"
  COMPONENT_FIELD = "components"
  DESCRIPTION_FIELD = "description"

  def save_issue(issue)
    fields = issue.fields

    SupportTicket.find_or_initialize_by(issue_key: issue.key).tap do |ticket|
      ticket.title = fields[TITLE_FIELD]
      ticket.opened_at = to_time(fields[CREATED_FIELD])
      ticket.jira_updated_at = to_time(fields[UPDATED_FIELD])
      ticket.components = extract_components(fields)
      ticket.priority = extract_name(fields[PRIORITY_FIELD])
      ticket.team = extract_team(fields)
      ticket.reporter = extract_name(fields[REPORTER_FIELD])
      ticket.status = extract_name(fields[STATUS_FIELD])
      ticket.assignee = extract_name(fields[RESPONSIBLE_FIELD])
      ticket.description = fields[DESCRIPTION_FIELD]
      ticket.save!
    end
  rescue StandardError => e
    Rails.logger.error "[SupportTicketsExtractor] Failed to save issue #{issue.key}: #{e.message}"
  end

  def to_time(value)
    return value if value.is_a?(Time)

    Time.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def extract_components(fields)
    Array(fields[COMPONENT_FIELD]).map { |c| c["name"] }.compact
  end

  def extract_team(fields)
    val = fields[TEAM_FIELD_PRIMARY].presence || fields[TEAM_FIELD_FALLBACK]
    return val["value"] || val["name"] if val.is_a?(Hash)

    val.to_s.presence
  end

  def extract_name(field_value)
    return nil if field_value.nil?
    return field_value["name"] || field_value["displayName"] if field_value.is_a?(Hash)

    field_value.to_s
  end
end
