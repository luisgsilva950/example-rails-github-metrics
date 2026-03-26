class SyncSonarIssues
  def initialize(client: SonarCloudClient.new)
    @client = client
  end

  def call(project:, since: nil)
    page = 1
    total_synced = 0

    loop do
      response = @client.issues(component_key: project.sonar_key, page: page, created_after: since)
      issues = response.fetch("issues", [])
      break if issues.empty?

      issues.each { |data| upsert_issue(project, data) }
      total_synced += issues.size

      break if total_synced >= response.dig("paging", "total").to_i

      page += 1
    end

    project.update!(issues_synced_at: Time.current)
    total_synced
  end

  private

  def upsert_issue(project, data)
    issue = project.sonar_issues.find_or_initialize_by(issue_key: data["key"])
    issue.update!(
      issue_type: data["type"],
      severity: data["severity"],
      status: data["status"],
      message: data["message"],
      component: data["component"],
      rule: data["rule"],
      line: data["line"],
      effort: data["effort"],
      creation_date: data["creationDate"],
      update_date: data["updateDate"],
      tags: data.fetch("tags", [])
    )
  end
end
