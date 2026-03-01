class Metrics::JiraBugsController < ApplicationController
  def unclassified
    page, size = pagination_params
    scope = base_scope_for(params[:team])
    result = JiraBugs::ListUnclassifiedBugs.new(jira_base_url: jira_base_url).call(scope: scope, page: page, size: size)

    render json: { content: result[:content], meta: result[:meta].merge(team: params[:team]) }
  end

  def by_category
    scope = JiraBug.done.where.not(categories: nil)
    scope = scope.by_team(params[:team]) if params[:team].present?
    categories_map = JiraBugs::GroupBugsByCategory.new(jira_base_url: jira_base_url).call(scope: scope)

    render json: { content: categories_map, meta: { total_categories: categories_map.size, team: params[:team] } }
  end

  def bubble_chart_page
    apply_default_filters
    @category_types = resolve_category_types
    @sub_category = params[:sub_category].presence

    scope = filtered_done_scope
    scope = scope.with_category_prefix(@sub_category) if @sub_category.present?

    result = JiraBugs::BuildCategoryAnalysis.new.call(scope: scope, category_types: @category_types, sub_category: @sub_category)
    @chart_labels = result[:chart_labels]
    @chart_values = result[:chart_values]
    @total_bugs = result[:total_bugs]
  end

  def bubble_chart
    scope = JiraBug.done.where.not(development_type: nil)
    scope = scope.by_team(params[:team]) if params[:team].present?
    result = JiraBugs::BuildBubbleChartData.new.call(scope: scope)

    render json: { data: result[:data], labels: result[:labels], meta: { team: params[:team] } }
  end

  def invalid_categories_page
    apply_default_filters
    scope = filtered_done_scope
    @invalid_bugs = JiraBugs::ListInvalidBugs.new(jira_base_url: jira_base_url).call(scope: scope)
  end

  def all_bugs_page
    apply_default_filters
    @status = params[:status]
    @missing_category = params[:missing_category]
    @feature_without_project = params[:feature_without_project] == "1"
    @no_categories = params[:no_categories] == "1"
    @categories_filter = Array(params[:categories_filter]).reject(&:blank?)
    @jira_base_url = jira_base_url
    @statuses = JiraBug.distinct.order(:status).pluck(:status).compact

    scope = JiraBug.all
    scope = scope.by_team(@team) if @team.present?
    scope = scope.by_date_range(@start_date, @end_date)

    result = JiraBugs::ListAllBugs.new(jira_base_url: jira_base_url).call(
      scope: scope,
      filters: {
        status: @status,
        missing_category: @missing_category,
        feature_without_project: @feature_without_project,
        no_categories: @no_categories,
        categories_filter: @categories_filter
      }
    )
    @bugs = result[:bugs]
    @total = result[:total]
  end

  def bugs_over_time_page
    apply_default_filters
    @group_by = params[:group_by].presence || "weekly"
    @category_filter = params[:category_filter].presence
    @group_by_category = params[:group_by_category].presence
    @sub_category = params[:sub_category].presence
    @top_n = params[:top_n].to_i
    @top_n = nil if @top_n <= 0

    scope = filtered_done_scope
    @available_categories = JiraBug.distinct_categories(scope)
    scope = scope.with_category(@category_filter) if @category_filter.present?

    result = JiraBugs::BuildBugsOverTime.new.call(
      scope: scope, group_by: @group_by, group_by_category: @group_by_category,
      sub_category: @sub_category, top_n: @top_n
    )

    @chart_labels = result[:chart_labels]
    @chart_values = result[:chart_values]
    @display_labels = result[:display_labels]
    @chart_datasets = result[:chart_datasets]
    @pie_data = result[:pie_data]
    @total_bugs = result[:total_bugs]
  end

  def sync_from_jira
    jql = build_sync_jql
    max_results = ENV.fetch("JIRA_MAX_RESULTS", "500").to_i

    JiraBugsExtractor.new(client: JiraClient.new, jql: jql, max_results: max_results).call

    redirect_to metrics_jira_bugs_invalid_categories_page_path(sync_redirect_params),
                notice: "JIRA sync completed successfully. JQL: #{jql}"
  rescue StandardError => e
    Rails.logger.error "[Jira] Sync failed: #{e.message}"
    redirect_to metrics_jira_bugs_invalid_categories_page_path(sync_redirect_params),
                alert: "JIRA sync failed: #{e.message}"
  end

  def invalid_categories
    page, size = pagination_params
    scope = base_scope_for(params[:team])
    all_invalid = JiraBugs::ListInvalidBugs.new(jira_base_url: jira_base_url).call(scope: scope)

    total = all_invalid.size
    paginated = all_invalid.slice((page - 1) * size, size) || []

    render json: {
      content: paginated,
      meta: { page: page, size: size, total: total, total_pages: (total.to_f / size).ceil, team: params[:team] }
    }
  end

  private

  def jira_base_url
    ENV.fetch("JIRA_SITE", "https://digitial-product-engineering.atlassian.net")
  end

  def base_scope_for(team)
    scope = JiraBug.done
    scope = scope.by_team(team) if team.present?
    scope
  end

  def filtered_done_scope
    scope = JiraBug.done
    scope = scope.by_team(@team) if @team.present?
    scope.by_date_range(@start_date, @end_date)
  end

  def apply_default_filters
    today = Time.current.in_time_zone(JiraBug::SAO_PAULO_TZ).to_date
    @team = params[:team].presence || "Digital Farm"
    @start_date = params[:start_date].presence || today.beginning_of_year.iso8601
    @end_date = params[:end_date].presence || today.iso8601
  end

  def resolve_category_types
    types = Array(params[:category_types]).reject(&:blank?)
    types = [ params[:category_type] ] if types.empty? && params[:category_type].present?
    types.empty? ? [ "feature" ] : types
  end

  def pagination_params
    page = [ params.fetch(:page, 1).to_i, 1 ].max
    size = params.fetch(:size, 25).to_i
    size = 25 if size <= 0
    size = [ size, 10_000 ].min
    [ page, size ]
  end

  def build_sync_jql
    jql = 'project = CWS AND type = Bug AND "squad[dropdown]" IN ("Digital Farm")'
    jql += " AND created >= '#{params[:start_date]}'" if params[:start_date].present?
    jql += " AND created <= '#{params[:end_date]}'" if params[:end_date].present?
    jql + " ORDER BY created DESC"
  end

  def sync_redirect_params
    { team: params[:team], start_date: params[:start_date], end_date: params[:end_date] }
  end
end
