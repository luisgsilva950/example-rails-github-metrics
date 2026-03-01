# frozen_string_literal: true

module JiraBugs
  # Validates that a bug's categories follow the required rules.
  # Returns an array of reason strings (empty if valid).
  class ValidateBugCategories
    def call(categories)
      categories = JiraBug.filter_categories(categories)
      return [] if data_integrity?(categories)

      build_reasons(categories)
    end

    private

    def data_integrity?(categories)
      categories.any? { |c| c.start_with?("data_integrity_reason:") }
    end

    def build_reasons(categories)
      reasons = []
      reasons << "missing_project_category" unless has_prefix?(categories, "project")
      reasons << "missing_feature_category" unless has_prefix?(categories, "feature")
      reasons << "missing_mfe_category" if cw_elements_without_mfe?(categories)
      reasons
    end

    def has_prefix?(categories, prefix)
      categories.any? { |c| c.start_with?("#{prefix}:") }
    end

    def cw_elements_without_mfe?(categories)
      categories.include?("project:cw_elements") && !has_prefix?(categories, "mfe")
    end
  end
end
