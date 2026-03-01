# frozen_string_literal: true

module JiraBugs
  # Finds bugs with invalid categories and returns them with reasons.
  class ListInvalidBugs
    def initialize(jira_base_url:, validator: ValidateBugCategories.new)
      @jira_base_url = jira_base_url
      @validator = validator
    end

    def call(scope:)
      invalid_bugs = collect_invalid(scope)
      sort_by_opened_desc(invalid_bugs)
    end

    private

    def collect_invalid(scope)
      scope.select(:id, :issue_key, :title, :categories, :opened_at).filter_map do |bug|
        categories = JiraBug.filter_categories(bug.categories)
        reasons = @validator.call(categories)
        next if reasons.empty?

        build_result(bug, reasons)
      end
    end

    def build_result(bug, reasons)
      {
        issue_key: bug.issue_key,
        title: bug.title,
        jira_link: "#{@jira_base_url}/browse/#{bug.issue_key}",
        categories: JiraBug.filter_categories(bug.categories),
        reasons: reasons,
        opened_at: bug.opened_at
      }
    end

    def sort_by_opened_desc(bugs)
      bugs.sort_by { |b| b[:opened_at] || Time.at(0) }.reverse
    end
  end
end
