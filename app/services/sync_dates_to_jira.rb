# frozen_string_literal: true

class SyncDatesToJira
  ISSUE_KEY_PATTERN = %r{/browse/([A-Z][A-Z0-9_]+-\d+)\z}

  def initialize(client: JiraClient.new)
    @client = client
  end

  def call(deliverable:)
    issue_key = extract_issue_key(deliverable.jira_link)
    return { success: false, error: "No valid Jira issue key found in link" } unless issue_key

    dates = compute_dates(deliverable)
    return { success: false, error: "No allocations found for this deliverable" } unless dates

    @client.update_issue(key: issue_key, fields: build_fields(dates))
    { success: true, issue_key: issue_key }
  end

  private

  def extract_issue_key(link)
    return nil if link.blank?

    link.match(ISSUE_KEY_PATTERN)&.captures&.first
  end

  def compute_dates(deliverable)
    allocations = deliverable.deliverable_allocations
    return nil unless allocations.exists?

    {
      start_date: allocations.minimum(:start_date),
      end_date: allocations.maximum(:end_date)
    }
  end

  def build_fields(dates)
    start_field = ENV.fetch("JIRA_PLANNED_START_DATE_FIELD", "customfield_10357")
    end_field = ENV.fetch("JIRA_PLANNED_END_DATE_FIELD", "customfield_10487")

    {
      start_field => dates[:start_date].iso8601,
      "customfield_10015" => dates[:start_date].iso8601,
      end_field => dates[:end_date].iso8601
    }
  end
end
