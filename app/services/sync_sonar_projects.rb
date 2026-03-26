class SyncSonarProjects
  def initialize(client: SonarCloudClient.new)
    @client = client
  end

  def call
    page = 1
    total_synced = 0

    loop do
      response = @client.projects(page: page)
      components = response.fetch("components", [])
      break if components.empty?

      components.each { |data| upsert_project(data) }
      total_synced += components.size

      break if total_synced >= response.dig("paging", "total").to_i

      page += 1
    end

    total_synced
  end

  private

  def upsert_project(data)
    project = SonarProject.find_or_initialize_by(sonar_key: data["key"])
    project.update!(
      name: data["name"],
      qualifier: data["qualifier"],
      visibility: data["visibility"],
      last_analysis_date: data["lastAnalysisDate"]
    )
  end
end
