class SyncSonarMetrics
  RATING_MAP = { 1.0 => "A", 2.0 => "B", 3.0 => "C", 4.0 => "D", 5.0 => "E" }.freeze

  def initialize(client: SonarCloudClient.new)
    @client = client
  end

  def call(since: nil)
    scope = projects_to_sync(since)
    scope.find_each { |project| sync_project_metrics(project) }
  end

  private

  def sync_project_metrics(project)
    response = @client.measures(component_key: project.sonar_key)
    metrics = parse_measures(response)

    project.update!(
      bugs: metrics["bugs"].to_i,
      vulnerabilities: metrics["vulnerabilities"].to_i,
      code_smells: metrics["code_smells"].to_i,
      security_hotspots: metrics["security_hotspots"].to_i,
      ncloc: metrics["ncloc"].to_i,
      coverage: metrics["coverage"].to_f,
      duplicated_lines_density: metrics["duplicated_lines_density"].to_f,
      reliability_rating: rating_label(metrics["reliability_rating"]),
      security_rating: rating_label(metrics["security_rating"]),
      sqale_rating: rating_label(metrics["sqale_rating"]),
      metrics_synced_at: Time.current
    )
  end

  def parse_measures(response)
    measures = response.dig("component", "measures") || []
    measures.each_with_object({}) { |m, hash| hash[m["metric"]] = m["value"] }
  end

  def projects_to_sync(since)
    return SonarProject.all if since.nil?

    SonarProject.where(metrics_synced_at: nil)
               .or(SonarProject.where(metrics_synced_at: ...since))
  end

  def rating_label(value)
    return nil if value.nil?

    RATING_MAP.fetch(value.to_f, value.to_s)
  end
end
