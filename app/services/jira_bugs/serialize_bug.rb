# frozen_string_literal: true

module JiraBugs
  # Formats a bug record into a hash for JSON serialization.
  class SerializeBug
    def initialize(jira_base_url:)
      @jira_base_url = jira_base_url
    end

    def call(bug)
      {
        issue_key: bug.issue_key,
        title: bug.title,
        jira_link: "#{@jira_base_url}/browse/#{bug.issue_key}",
        categories: JiraBug.filter_categories(bug.categories),
        development_type: bug.development_type,
        components: bug.components,
        opened_at: bug.opened_at
      }
    end
  end
end
