# frozen_string_literal: true

module JiraBugs
  # Builds a combo label from a bug's categories matching given prefixes.
  # Example: "feature:login + project:auth"
  class BuildCategoryCombo
    def call(bug:, prefixes:, include_dev_type: false)
      parts = matched_categories(bug, prefixes)
      parts << bug.development_type if include_dev_type && bug.development_type.present?
      parts.join(" + ")
    end

    private

    def matched_categories(bug, prefixes)
      cats = JiraBug.filter_categories(bug.categories)

      prefixes.each_with_object([]) do |prefix, result|
        matched = cats.select { |c| c.start_with?("#{prefix}:") }
        result.concat(matched.sort)
      end
    end
  end
end
