# frozen_string_literal: true

module JiraBugs
  # Builds bubble chart data: feature × development_type matrix with counts.
  class BuildBubbleChartData
    def call(scope:)
      counts = count_feature_dev_type(scope)
      build_chart(counts)
    end

    private

    def count_feature_dev_type(scope)
      counts = Hash.new(0)

      scope.select(:id, :categories, :development_type).find_each do |bug|
        features(bug).each do |feature|
          counts[[bug.development_type, feature]] += 1
        end
      end

      counts
    end

    def features(bug)
      JiraBug.filter_categories(bug.categories)
             .select { |c| c.start_with?("feature:") }
    end

    def build_chart(counts)
      dev_types = counts.keys.map(&:first).uniq.sort
      feature_list = counts.keys.map(&:last).uniq.sort

      data = counts.map do |(dev_type, feature), count|
        build_point(dev_type, feature, count, dev_types, feature_list)
      end

      { data: data, labels: { x: feature_list, y: dev_types } }
    end

    def build_point(dev_type, feature, count, dev_types, features)
      {
        x: features.index(feature),
        y: dev_types.index(dev_type),
        r: count,
        development_type: dev_type,
        feature: feature,
        count: count
      }
    end
  end
end
