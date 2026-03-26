module Sonar
  class DashboardController < BaseController
    def index
      @dashboard = build_dashboard
    end

    def opened
      @breakdown = opened_breakdown
    end

    private

    def build_dashboard
      severity = params[:severity]
      projects = filtered_projects(severity)
      scope = severity == "CRITICAL" ? SonarIssue.critical_or_blocker : SonarIssue.all

      {
        severity: severity,
        projects: projects,
        critical_counts: severity == "CRITICAL" ? SonarIssue.critical_counts_by_project : {},
        critical_issues: severity == "CRITICAL" ? scope.open.where(sonar_project_id: projects.map(&:id)) : SonarIssue.none,
        issue_stats: { open: scope.open.count, resolved: scope.resolved.count },
        sync_setting: SyncSetting.for("sonar_metrics")
      }
    end

    def opened_breakdown
      severity = params[:severity]
      scope = severity == "CRITICAL" ? SonarIssue.open.critical_or_blocker : SonarIssue.open
      counts = scope.group(:rule).order("count_all DESC").count
      descriptions = scope.where(rule: counts.keys).group(:rule).pick_descriptions
      rule_details = OpenedIssuesByRuleQuery.new(scope: scope).call

      {
        severity: severity,
        rule_counts: counts,
        rule_descriptions: descriptions,
        rule_details: rule_details,
        total: counts.values.sum
      }
    end

    def filtered_projects(severity)
      return SonarProject.ranked_by_critical_count if severity == "CRITICAL"

      SonarProject.ordered_by_total_issues
    end
  end
end
