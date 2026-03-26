class OpenedIssuesByRuleQuery
  def initialize(scope: SonarIssue.open)
    @scope = scope.includes(:sonar_project)
  end

  def call
    issues = @scope.select(:rule, :component, :sonar_project_id).to_a
    build_rule_details(issues)
  end

  private

  def build_rule_details(issues)
    issues.group_by(&:rule).transform_values { |group| build_repos(group) }
  end

  def build_repos(issues)
    issues.group_by { |i| i.sonar_project.name }.transform_values do |repo_issues|
      repo_issues.filter_map { |i| extract_filename(i.component) }.uniq.sort
    end
  end

  def extract_filename(component)
    return if component.blank?

    component.sub(/\A[^:]+:/, "")
  end
end
