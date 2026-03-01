# frozen_string_literal: true

module JiraBugs
  # Builds category analysis data for the horizontal bar chart page.
  # Groups bugs by category combo and returns sorted labels/values.
  class BuildCategoryAnalysis
    def initialize(combo_builder: BuildCategoryCombo.new)
      @combo_builder = combo_builder
    end

    def call(scope:, category_types:, sub_category: nil)
      include_dev_type = category_types.include?("development_type")
      prefixes = build_prefixes(category_types, sub_category)
      select_fields = build_select_fields(include_dev_type)

      counts = count_combos(scope, select_fields, prefixes, include_dev_type)
      sorted = counts.sort_by { |_, v| -v }

      {
        chart_labels: sorted.map(&:first),
        chart_values: sorted.map(&:last),
        total_bugs: sorted.sum { |_, v| v }
      }
    end

    private

    def build_prefixes(category_types, sub_category)
      prefixes = category_types.reject { |t| t == "development_type" }
      prefixes << sub_category if sub_category.present? && !prefixes.include?(sub_category)
      prefixes
    end

    def build_select_fields(include_dev_type)
      fields = [ :id, :categories ]
      fields << :development_type if include_dev_type
      fields
    end

    def count_combos(scope, select_fields, prefixes, include_dev_type)
      counts = Hash.new(0)

      scope.select(*select_fields).find_each do |bug|
        combo = @combo_builder.call(bug: bug, prefixes: prefixes, include_dev_type: include_dev_type)
        counts[combo] += 1 unless combo.empty?
      end

      counts
    end
  end
end
