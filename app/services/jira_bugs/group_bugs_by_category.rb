# frozen_string_literal: true

module JiraBugs
  # Groups done bugs by category and returns a map of category → JIRA links.
  class GroupBugsByCategory
    def initialize(jira_base_url:)
      @jira_base_url = jira_base_url
    end

    def call(scope:)
      categories_map = Hash.new { |h, k| h[k] = [] }

      scope.select(:id, :issue_key, :categories).find_each do |bug|
        link = "#{@jira_base_url}/browse/#{bug.issue_key}"
        each_category(bug) { |cat| categories_map[cat] << link }
      end

      categories_map.sort_by { |k, _| k }.to_h
    end

    private

    def each_category(bug)
      JiraBug.filter_categories(bug.categories).each { |cat| yield cat }
    end
  end
end
