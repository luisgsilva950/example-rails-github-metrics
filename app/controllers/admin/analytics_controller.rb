require "set"

module Admin
  class AnalyticsController < BaseController
    JIRA_CLOSED_STATUSES = %w[Done Closed Resolved Cancelled Canceled Completed Fix Committed Released].freeze

    def index
      @active_tab = permitted_tab

      load_author_metrics
      load_repository_metrics
      load_jira_metrics
      load_resolved_bugs_metrics
      load_overview_metrics
    end

    private

    def load_author_metrics
      return unless %w[authors retrospective].include?(@active_tab)

      @author_opened_from = safe_parse_date(params[:author_opened_from])
      @stats = author_stats(opened_after: @author_opened_from)
      @normalized_author_options = @stats.map { |row| row[:normalized_author_name] }.compact.uniq.sort
      @selected_authors = Array(params[:normalized_author_names]).reject(&:blank?)
      @selected_authors = default_author_names if @selected_authors.blank?

      filtered_stats = filter_rows(@stats, @selected_authors, :normalized_author_name)

      @top_pull_request_authors = filtered_stats.sort_by { |row| -row[:pull_requests_count] }.first(8)
      @top_change_volume_authors = filtered_stats.sort_by { |row| -row[:total_changes] }.first(8)
      @top_average_change_authors = filtered_stats
        .select { |row| row[:total_files].positive? }
        .map { |row| row.merge(avg_changes_per_file: row[:total_changes].to_f / row[:total_files]) }
        .sort_by { |row| -row[:avg_changes_per_file] }
        .first(8)

      @largest_pull_requests = top_pull_requests_by_changes(@selected_authors, opened_after: @author_opened_from)
      @authors_over_threshold = authors_with_large_changes(@selected_authors, opened_after: @author_opened_from)
    end

    def load_repository_metrics
      return unless %w[repositories retrospective].include?(@active_tab)

      @repository_opened_from = safe_parse_date(params[:repository_opened_from])
      @repository_stats = repository_stats(opened_after: @repository_opened_from)
      @repository_options = @repository_stats.map { |row| row[:repository_name] }.compact.uniq.sort
      @selected_repositories = Array(params[:repository_names]).reject(&:blank?)

      filtered_stats = filter_rows(@repository_stats, @selected_repositories, :repository_name)

      @top_repository_prs = filtered_stats.sort_by { |row| -row[:pull_requests_count] }.first(8)
      @top_repository_changes = filtered_stats.sort_by { |row| -row[:total_changes] }.first(8)
      @top_repository_avg_changes = filtered_stats
        .select { |row| row[:total_files].positive? }
        .map { |row| row.merge(avg_changes_per_file: row[:total_changes].to_f / row[:total_files]) }
        .sort_by { |row| -row[:avg_changes_per_file] }
        .first(8)
    end

    def load_jira_metrics
      return unless %w[jira_bugs retrospective].include?(@active_tab)

      scope = JiraBug.all
      @jira_team_options = JiraBug.where.not(team: [ nil, "" ]).distinct.order(:team).pluck(:team)
      @selected_jira_teams = Array(params[:jira_team_names]).reject(&:blank?)
      scope = scope.where(team: @selected_jira_teams) if @selected_jira_teams.any?
      @jira_opened_from = safe_parse_date(params[:jira_opened_from])
      scope = scope.where("opened_at >= ?", @jira_opened_from.beginning_of_day) if @jira_opened_from

      @jira_top_teams = jira_grouped_counts(scope, :team, :team)
      @jira_priority_counts = jira_grouped_counts(scope, :priority, :priority)
      @jira_status_counts = jira_grouped_counts(scope, :status, :status)

      @jira_component_counts = jira_component_counts(scope)
      top_components_for_breakdown = @jira_component_counts.first(4).map { |row| row[:component] }
      @jira_component_priority_breakdown = jira_component_priority_breakdown(scope, top_components_for_breakdown)
      @jira_component_time_series = jira_component_time_series(scope)
      @jira_top_bug_months = top_bug_months(scope)
      @jira_bottom_bug_months = bottom_bug_months(scope)

      open_scope = scope.where.not(status: JIRA_CLOSED_STATUSES)
      oldest_open_scope = open_scope.where.not(opened_at: nil)
      @jira_oldest_open_bugs = oldest_open_scope.order(opened_at: :asc).limit(3)
    end

    def load_resolved_bugs_metrics
      return unless %w[resolved_bugs retrospective].include?(@active_tab)

      resolved_since = 1.year.ago.beginning_of_day
      @resolved_timeframe_label = I18n.l(resolved_since.to_date, format: :long)

      table = JiraBug.arel_table
      resolved_scope = JiraBug.where(table[:status].matches("%Done%"))
                               .where("COALESCE(jira_updated_at, updated_at, opened_at) >= ?", resolved_since)

      @resolved_opened_from = safe_parse_date(params[:resolved_opened_from])
      if @resolved_opened_from
        resolved_scope = resolved_scope.where("opened_at >= ?", @resolved_opened_from.beginning_of_day)
      end

      @resolved_team_options = resolved_scope.where.not(team: [ nil, "" ])
                                             .distinct
                                             .order(:team)
                                             .pluck(:team)
      @selected_resolved_teams = Array(params[:resolved_team_names]).reject(&:blank?)
      default_bug_team = "DA Backbone"
      if @selected_resolved_teams.blank? && @resolved_team_options.include?(default_bug_team)
        @selected_resolved_teams = [default_bug_team]
      end
      resolved_scope = resolved_scope.where(team: @selected_resolved_teams) if @selected_resolved_teams.any?

      resolved_scope = resolved_scope.where.not(assignee: [ nil, "" ])

      @resolved_bug_leaders = resolved_scope
                               .group(:assignee)
                               .select("assignee, COUNT(*) AS bug_count")
                               .order(Arel.sql("bug_count DESC"))
                               .limit(3)
                               .map { |row| { assignee: row.assignee, bug_count: row.bug_count.to_i } }

      @resolved_bug_by_team = resolved_scope
                               .where.not(team: [ nil, "" ])
                               .group(:team)
                               .select("team, COUNT(*) AS bug_count")
                               .order(Arel.sql("bug_count DESC"))
                               .limit(3)
                               .map { |row| { team: row.team, bug_count: row.bug_count.to_i } }
    end

    def filter_rows(rows, selected_values, key)
      return rows if selected_values.blank?

      rows.select { |row| selected_values.include?(row[key]) }
    end

    def author_stats(opened_after: nil)
      cache_key = opened_after ? opened_after.to_date : :all
      @author_stats_cache ||= {}
      return @author_stats_cache[cache_key] if @author_stats_cache.key?(cache_key)

      normalizer = author_name_normalizer
      stats = Hash.new do |hash, key|
        hash[key] = {
          normalized_author_name: key,
          pull_requests_count: 0,
          total_changes: 0,
          total_files: 0
        }
      end

      scope = PullRequest.where.not(author_name: nil)
      scope = scope.where("opened_at >= ?", opened_after.beginning_of_day) if opened_after

      scope.find_each(batch_size: 200) do |pr|
        normalized_name = normalizer.call(pr.author_name)
        next if normalized_name.blank?

        entry = stats[normalized_name]
        entry[:normalized_author_name] = normalized_name
        entry[:pull_requests_count] += 1
        entry[:total_changes] += pr.additions.to_i + pr.deletions.to_i
        entry[:total_files] += pr.changed_files.to_i
      end

      result = stats.values
      author_stats_cache = (@author_stats_cache ||= {})
      author_stats_cache[cache_key] = result
    end

    def repository_stats(opened_after: nil)
      cache_key = opened_after ? opened_after.to_date : :all
      @repository_stats_cache ||= {}
      return @repository_stats_cache[cache_key] if @repository_stats_cache.key?(cache_key)

      normalizer = author_name_normalizer
      stats = Hash.new do |hash, key|
        hash[key] = {
          repository_name: key,
          pull_requests_count: 0,
          total_changes: 0,
          total_files: 0,
          contributors: Set.new
        }
      end

      scope = PullRequest.includes(:repository).where.not(repository_id: nil)
      scope = scope.where("opened_at >= ?", opened_after.beginning_of_day) if opened_after

      scope.find_each(batch_size: 200) do |pr|
        repo_name = pr.repository&.name
        next if repo_name.blank?

        entry = stats[repo_name]
        entry[:repository_name] = repo_name
        entry[:pull_requests_count] += 1
        entry[:total_changes] += pr.additions.to_i + pr.deletions.to_i
        entry[:total_files] += pr.changed_files.to_i

        normalized_author = pr.normalized_author_name.presence || normalizer.call(pr.author_name)
        entry[:contributors] << normalized_author if normalized_author.present?
      end

      result = stats.values.map do |row|
        row[:contributors] = row[:contributors].size
        row
      end
      repository_stats_cache = (@repository_stats_cache ||= {})
      repository_stats_cache[cache_key] = result
    end

    def author_name_normalizer
      @author_name_normalizer ||= AuthorNameNormalizer.new
    end

    def top_pull_requests_by_changes(selected_authors, opened_after: nil)
      normalizer = author_name_normalizer
      scope = PullRequest.includes(:repository)
             .order(Arel.sql("(COALESCE(additions, 0) + COALESCE(deletions, 0)) DESC"))
      scope = scope.where("opened_at >= ?", opened_after.beginning_of_day) if opened_after
      prs = scope.map do |pr|
        normalized_name = normalizer.call(pr.author_name)
        next if normalized_name.blank?
        next if selected_authors.any? && !selected_authors.include?(normalized_name)

        total_changes = pr.additions.to_i + pr.deletions.to_i
        avg_changes = if pr.changed_files.to_i.positive?
                        total_changes.to_f / pr.changed_files.to_i
                      end

        {
          pull_request: pr,
          normalized_author_name: normalized_name,
          total_changes: total_changes,
          additions: pr.additions.to_i,
          deletions: pr.deletions.to_i,
          changed_files: pr.changed_files.to_i,
          average_changes_per_file: avg_changes
        }
      end.compact

      prs.sort_by { |row| -row[:total_changes] }.first(8)
    end

    def authors_with_large_changes(selected_authors, opened_after: nil)
      normalizer = author_name_normalizer
      scope = PullRequest.where("COALESCE(additions, 0) + COALESCE(deletions, 0) >= 2000")
      scope = scope.where("opened_at >= ?", opened_after.beginning_of_day) if opened_after
      scope = scope.where(normalized_author_name: selected_authors) if selected_authors.any?

      counts = Hash.new(0)

      scope.find_each(batch_size: 200) do |pr|
        normalized = pr.normalized_author_name.presence || normalizer.call(pr.author_name)
        next if normalized.blank?

        counts[normalized] += 1
      end

      counts.map { |author, value| { normalized_author_name: author, pr_count: value } }
            .sort_by { |row| -row[:pr_count] }
    end

    def permitted_tab
      tab = params[:tab].to_s
      %w[overview retrospective authors repositories jira_bugs resolved_bugs].include?(tab) ? tab : "overview"
    end

    def load_overview_metrics
      return unless %w[overview retrospective].include?(@active_tab)

      @overview_year = 2025
      year_start = Time.zone.local(@overview_year, 1, 1).beginning_of_day
      year_end = year_start.end_of_year

      merged_scope = PullRequest.includes(:repository)
                                .where.not(merged_at: nil)
                                .where(merged_at: year_start..year_end)

      @overview_author_options = merged_scope.where.not(normalized_author_name: [ nil, "" ])
                                             .distinct
                                             .order(:normalized_author_name)
                                             .pluck(:normalized_author_name)
      @overview_selected_authors = Array(params[:overview_author_names]).reject(&:blank?)
      @overview_selected_authors = default_author_names if @overview_selected_authors.blank?
      merged_scope = merged_scope.where(normalized_author_name: @overview_selected_authors) if @overview_selected_authors.any?

      @overview_total_merges_2025 = merged_scope.count
      @overview_repositories_2025 = merged_scope.select(:repository_id).distinct.count
      @overview_contributor_count = merged_scope.select(:normalized_author_name).distinct.count

      language_totals = Hash.new { |hash, key| hash[key] = { language: key || "Unknown", pull_requests: 0, total_changes: 0 } }

      merged_scope.find_each(batch_size: 200) do |pr|
        language = pr.repository&.language.presence || "Unknown"
        entry = language_totals[language]
        entry[:pull_requests] += 1
        entry[:total_changes] += pr.additions.to_i + pr.deletions.to_i
      end

      @overview_language_stats = language_totals.values
                                                 .sort_by { |row| -row[:total_changes] }
                                                 .first(6)

      @overview_review_turnaround = review_turnaround_for(merged_scope)
      @overview_monthly_merge_velocity = monthly_merge_velocity(merged_scope, year_start)
      @overview_busiest_month = @overview_monthly_merge_velocity.max_by { |row| row[:value].to_i }
      if @overview_monthly_merge_velocity.any?
        total_velocity = @overview_monthly_merge_velocity.sum { |row| row[:value].to_i }
        @overview_average_monthly_merges = (total_velocity.to_f / @overview_monthly_merge_velocity.size).round
      end

      @overview_top_repositories = top_repositories_for(merged_scope)
      @overview_top_authors = top_authors_for(merged_scope)

      commits_scope = Commit.includes(:repository)
                 .where(committed_at: year_start..year_end)
      commits_scope = commits_scope.where(normalized_author_name: @overview_selected_authors) if @overview_selected_authors.any?
      commit_extremes = overview_commit_extremes(commits_scope)
      @overview_early_commit = commit_extremes[:early]
      @overview_late_commit = commit_extremes[:late]
      @overview_first_commit = earliest_commit(commits_scope)
    end

    def top_repositories_for(scope)
      base_scope = scope.except(:select, :order, :includes)
      aggregated = base_scope
        .joins(:repository)
        .where.not(repositories: { name: [ nil, "" ] })
        .group("repositories.name")
        .select("repositories.name AS repo_name, COUNT(*) AS merge_count, SUM(COALESCE(additions, 0) + COALESCE(deletions, 0)) AS total_changes")
        .order(Arel.sql("merge_count DESC"))
        .limit(3)
      aggregated.map do |row|
        {
          name: row.repo_name,
          merges: row.merge_count.to_i,
          changes: row.total_changes.to_i
        }
      end
    end

    def top_authors_for(scope)
      base_scope = scope.except(:select, :order, :includes)
      aggregated = base_scope
        .where.not(normalized_author_name: [ nil, "" ])
        .group(:normalized_author_name)
        .select("normalized_author_name, COUNT(*) AS merge_count, SUM(COALESCE(additions, 0) + COALESCE(deletions, 0)) AS total_changes")
        .order(Arel.sql("merge_count DESC"))
        .limit(3)
      aggregated.map do |row|
          {
            name: row.normalized_author_name,
            merges: row.merge_count.to_i,
            changes: row.total_changes.to_i
          }
        end
    end

    def safe_parse_date(value)
      return if value.blank?

      Date.parse(value)
    rescue ArgumentError
      nil
    end

    def overview_commit_extremes(commits_scope)
      zone = brt_time_zone
      early_candidate = nil
      late_candidate = nil

      commits_scope.find_each(batch_size: 500) do |commit|
        brt_time = commit_time_in_zone(commit, zone)
        next unless brt_time

        minutes = minutes_since_midnight(brt_time)

        if work_hours?(brt_time)
          if early_candidate.nil? || minutes < early_candidate[:minutes]
            early_candidate = { commit: commit, minutes: minutes }
          end
        else
            after_hours_score = wrap_after_hours_minutes(minutes)
            if late_candidate.nil? || after_hours_score > late_candidate[:score]
              late_candidate = { commit: commit, score: after_hours_score }
          end
        end
      end

      {
        early: build_commit_snapshot(early_candidate&.dig(:commit), zone, "Work-hours"),
        late: build_commit_snapshot(late_candidate&.dig(:commit), zone, "After-hours")
      }
    end
    def wrap_after_hours_minutes(minutes)
      work_start_minutes = 7 * 60
      minutes < work_start_minutes ? minutes + 24 * 60 : minutes
    end

    def earliest_commit(commits_scope)
      zone = brt_time_zone
      commit = commits_scope.order(:committed_at).first
      build_commit_snapshot(commit, zone, "Year opener")
    end

    def build_commit_snapshot(commit, zone, label)
      return nil unless commit&.committed_at

      {
        author: commit.normalized_author_name.presence || commit.author_name.presence || "Unknown author",
        repository: commit.repository&.name || "Unknown repository",
        time: commit.committed_at.in_time_zone(zone),
        sha: commit.sha,
        label: label
      }
    end

    def brt_time_zone
      ActiveSupport::TimeZone["America/Sao_Paulo"] || Time.zone
    end

    def work_hours?(time)
      hour = time.hour
      hour >= 5 && hour <= 19
    end

    def commit_time_in_zone(commit, zone)
      return unless commit&.committed_at

      commit.committed_at.in_time_zone(zone)
    end

    def minutes_since_midnight(time)
      (time.hour * 60) + time.min + (time.sec / 60.0)
    end

    def default_author_names
      @default_author_names ||= ENV.fetch("ADMIN_PANEL_DEFAULT_AUTHOR_NAMES", "")
                                   .split(",")
                                   .map { |name| name.delete_prefix("'").delete_suffix("'").strip }
                                   .reject(&:blank?)
    end

    def review_turnaround_for(scope)
      merged_prs = scope.where.not(opened_at: nil)
      durations = merged_prs.pluck(:opened_at, :merged_at).map do |opened_at, merged_at|
        next if opened_at.blank? || merged_at.blank?
        merged_at - opened_at
      end.compact

      return nil if durations.empty?

      average_seconds = durations.sum / durations.size
      ActiveSupport::Duration.build(average_seconds)
    end

    def monthly_merge_velocity(scope, year_start)
      months = (0..11).map { |offset| (year_start + offset.months).beginning_of_month }
      counts = months.map do |month|
        total = scope.where(merged_at: month..month.end_of_month).count
        { label: month.strftime("%b"), value: total }
      end

      counts
    end

    def top_bug_months(scope)
      since = 1.year.ago.beginning_of_month
      scoped = scope.where.not(opened_at: nil)
      scoped = scoped.where("opened_at >= ?", since)

      scoped
        .group("DATE_TRUNC('month', opened_at)")
        .select("DATE_TRUNC('month', opened_at) AS month_bucket, COUNT(*) AS bug_count")
        .order(Arel.sql("bug_count DESC"))
        .limit(3)
        .map do |row|
          month = row.month_bucket.to_date
          {
            label: I18n.l(month, format: "%B %Y"),
            bug_count: row.bug_count.to_i
          }
        end
    end

    def bottom_bug_months(scope)
      since = 1.year.ago.beginning_of_month
      scoped = scope.where.not(opened_at: nil)
      scoped = scoped.where("opened_at >= ?", since)

      scoped
        .group("DATE_TRUNC('month', opened_at)")
        .select("DATE_TRUNC('month', opened_at) AS month_bucket, COUNT(*) AS bug_count")
        .order(Arel.sql("bug_count ASC"))
        .limit(3)
        .map do |row|
          month = row.month_bucket.to_date
          {
            label: I18n.l(month, format: "%B %Y"),
            bug_count: row.bug_count.to_i
          }
        end
    end

    def jira_grouped_counts(scope, column_name, key_name)
      scope.where.not(column_name => [ nil, "" ])
           .group(column_name)
           .count
           .map { |value, count| { key_name => value, bug_count: count } }
           .sort_by { |row| -row[:bug_count] }
           .first(8)
    end

    def jira_component_counts(scope)
      counts = Hash.new(0)

      scope.find_each(batch_size: 200) do |bug|
        Array(bug.components).each do |component|
          next if component.blank?

          counts[component] += 1
        end
      end

      counts.map { |component, count| { component: component, bug_count: count } }
            .sort_by { |row| -row[:bug_count] }
            .first(8)
    end

    def jira_component_priority_breakdown(scope, components)
      component_set = components.compact.to_set
      return [] if component_set.empty?

      breakdown = Hash.new { |hash, component| hash[component] = Hash.new(0) }

      scope.find_each(batch_size: 200) do |bug|
        priority = bug.priority.presence || "No priority"
        Array(bug.components).each do |component|
          next unless component_set.include?(component)

          breakdown[component][priority] += 1
        end
      end

      breakdown.map do |component, priority_counts|
        totals = priority_counts.values
        {
          component: component,
          total: totals.sum,
          priorities: priority_counts.map { |priority, count| { priority: priority, count: count } }
                                      .sort_by { |row| -row[:count] }
        }
      end.sort_by { |row| components.index(row[:component]) || components.size }
    end

    def jira_component_time_series(scope)
      range_start = 6.months.ago.beginning_of_month
      month_trunc = Arel.sql("DATE_TRUNC('month', opened_at)")
      grouped = scope.where("opened_at >= ?", range_start)
              .joins("CROSS JOIN LATERAL unnest(components) AS component_name")
              .group(month_trunc, "component_name")
              .order(month_trunc)
              .count

      months = (0..5).map { |i| (range_start + i.months).beginning_of_month }
      datasets = Hash.new { |hash, key| hash[key] = Array.new(months.length, 0) }

      grouped.each do |(month, component), count|
        index = months.index(month.beginning_of_month)
        next unless index

        datasets[component][index] = count
      end

      {
        labels: months.map { |month| I18n.l(month.to_date, format: "%b/%Y") },
        datasets: datasets.map do |component, data|
          { label: component, data: data }
        end
      }
    end
  end
end
