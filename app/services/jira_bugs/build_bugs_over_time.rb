# frozen_string_literal: true

module JiraBugs
  # Builds time series chart data for "Bugs Over Time" page.
  # Category filtering is handled at the controller level via scopes.
  # Grouping by category (multi-series) is handled here when group_by_category is present.
  class BuildBugsOverTime
    def initialize(combo_builder: BuildCategoryCombo.new)
      @combo_builder = combo_builder
    end

    def call(scope:, group_by:, group_by_category: nil, sub_category: nil, top_n: nil)
      @bucket = FormatTimeBucket.new(group_by: group_by)
      @tz = Time.find_zone(JiraBug::SAO_PAULO_TZ)

      if group_by_category.present?
        build_categorized(scope, group_by_category, sub_category, top_n)
      else
        build_totals(scope)
      end
    end

    private

    def build_categorized(scope, group_by_category, sub_category, top_n)
      scoped = scope.with_category_prefix(group_by_category)
      series, all_keys = aggregate_series(scoped, group_by_category, sub_category)

      sorted_keys = all_keys.sort
      datasets = build_datasets(series, sorted_keys, top_n)
      pie_data = build_pie_data(series, top_n)

      {
        chart_labels: sorted_keys,
        display_labels: sorted_keys.map { |k| @bucket.format_label(k) },
        chart_datasets: datasets,
        chart_values: nil,
        pie_data: pie_data,
        total_bugs: scoped.count
      }
    end

    def build_totals(scope)
      counts = count_by_time(scope)
      sorted = counts.sort_by { |k, _| k }

      labels = sorted.map(&:first)
      values = sorted.map(&:last)

      {
        chart_labels: labels,
        display_labels: labels.map { |k| @bucket.format_label(k) },
        chart_datasets: nil,
        chart_values: values,
        pie_data: nil,
        total_bugs: values.sum
      }
    end

    def aggregate_series(scope, group_by_category, sub_category)
      series = Hash.new { |h, k| h[k] = Hash.new(0) }
      all_keys = Set.new
      prefixes = build_prefixes(group_by_category, sub_category)

      scope.select(:id, :opened_at, :categories).find_each do |bug|
        next unless bug.opened_at

        time_key = @bucket.bucket(bug.opened_at.in_time_zone(@tz))
        all_keys << time_key

        combo = @combo_builder.call(bug: bug, prefixes: prefixes)
        series[combo][time_key] += 1 unless combo.empty?
      end

      [series, all_keys]
    end

    def build_prefixes(group_by_category, sub_category)
      prefixes = [group_by_category]
      prefixes << sub_category if sub_category.present? && sub_category != group_by_category
      prefixes
    end

    def build_datasets(series, sorted_keys, top_n)
      datasets = series.sort_by { |name, _| name }.map do |name, counts_hash|
        { name: name, values: sorted_keys.map { |k| counts_hash[k] } }
      end

      return datasets unless top_n

      datasets.sort_by { |ds| -ds[:values].sum }
              .first(top_n)
              .sort_by { |ds| ds[:name] }
    end

    def build_pie_data(series, top_n)
      totals = series.transform_values { |h| h.values.sum }
                     .sort_by { |_, v| -v }
      totals = totals.first(top_n) if top_n

      totals.map { |name, count| { name: name, count: count } }
    end

    def count_by_time(scope)
      counts = Hash.new(0)

      scope.select(:id, :opened_at).find_each do |bug|
        next unless bug.opened_at

        key = @bucket.bucket(bug.opened_at.in_time_zone(@tz))
        counts[key] += 1
      end

      counts
    end
  end
end
