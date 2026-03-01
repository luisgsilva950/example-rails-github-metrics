# frozen_string_literal: true

module JiraBugs
  # Lists all bugs with comprehensive filtering.
  # Returns a hash with :bugs array and :total count.
  class ListAllBugs
    def initialize(jira_base_url:)
      @jira_base_url = jira_base_url
    end

    def call(scope:, filters: {})
      scope = apply_filters(scope, filters)

      bugs = scope.order(opened_at: :desc)
                  .select(*selected_fields)
                  .filter_map { |bug| apply_post_filters(bug, filters) }

      { bugs: bugs, total: bugs.size }
    end

    private

    def selected_fields
      [ :id, :issue_key, :title, :status, :development_type, :components, :categories, :opened_at ]
    end

    def apply_filters(scope, filters)
      scope = scope.where(status: filters[:status]) if filters[:status].present?
      scope = scope.where("categories = '{}'") if filters[:no_categories]
      apply_categories_filter(scope, filters[:categories_filter])
    end

    def apply_categories_filter(scope, categories)
      return scope if categories.blank?

      Array(categories).each do |cat|
        scope = scope.where("? = ANY(categories)", cat)
      end
      scope
    end

    def apply_post_filters(bug, filters)
      return nil if excluded_by_missing?(bug, filters[:missing_category])
      return nil if excluded_by_feature_project?(bug, filters[:feature_without_project])

      serialize(bug)
    end

    def excluded_by_missing?(bug, missing_category)
      return false if missing_category.blank?

      Array(bug.categories).any? { |c| c.start_with?("#{missing_category}:") }
    end

    def excluded_by_feature_project?(bug, feature_without_project)
      return false unless feature_without_project

      cats = Array(bug.categories)
      has_feature = cats.any? { |c| c.start_with?("feature:") }
      has_project = cats.any? { |c| c.start_with?("project:") }
      !(has_feature && !has_project)
    end

    def serialize(bug)
      {
        issue_key: bug.issue_key,
        title: bug.title,
        jira_link: "#{@jira_base_url}/browse/#{bug.issue_key}",
        status: bug.status,
        development_type: bug.development_type,
        components: Array(bug.components),
        categories: JiraBug.filter_categories(bug.categories),
        opened_at: bug.opened_at
      }
    end
  end
end
