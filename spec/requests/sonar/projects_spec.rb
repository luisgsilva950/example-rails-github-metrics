# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sonar::Projects", type: :request do
  describe "GET /sonar/projects/:id" do
    it "renders the project detail page" do
      project = create(:sonar_project, name: "my-service", bugs: 5)

      get "/sonar/projects/#{project.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("my-service")
    end

    it "displays project issues" do
      project = create(:sonar_project)
      create(:sonar_issue, sonar_project: project, message: "Null pointer risk", issue_type: "BUG")

      get "/sonar/projects/#{project.id}"

      expect(response.body).to include("Null pointer risk")
      expect(response.body).to include("Bug")
    end

    it "filters issues by type" do
      project = create(:sonar_project)
      create(:sonar_issue, sonar_project: project, issue_type: "BUG", message: "A bug here")
      create(:sonar_issue, sonar_project: project, issue_type: "CODE_SMELL", message: "Smell here")

      get "/sonar/projects/#{project.id}", params: { type: "BUG" }

      expect(response.body).to include("A bug here")
      expect(response.body).not_to include("Smell here")
    end

    it "filters issues by severity" do
      project = create(:sonar_project)
      create(:sonar_issue, sonar_project: project, severity: "CRITICAL", message: "Critical issue")
      create(:sonar_issue, sonar_project: project, severity: "MINOR", message: "Minor issue")

      get "/sonar/projects/#{project.id}", params: { severity: "CRITICAL" }

      expect(response.body).to include("Critical issue")
      expect(response.body).not_to include("Minor issue")
    end

    it "shows empty state when no issues" do
      project = create(:sonar_project)

      get "/sonar/projects/#{project.id}"

      expect(response.body).to include("No issues found")
    end
  end

  describe "POST /sonar/projects/:id/sync_issues" do
    it "syncs issues and redirects" do
      project = create(:sonar_project, sonar_key: "org_repo")

      fake_client = instance_double(SonarCloudClient)
      allow(SonarCloudClient).to receive(:new).and_return(fake_client)
      allow(fake_client).to receive(:issues).and_return(
        "paging" => { "total" => 0 },
        "issues" => []
      )

      post "/sonar/projects/#{project.id}/sync_issues"

      expect(response).to redirect_to(sonar_project_path(project))
      follow_redirect!
      expect(response.body).to include("Issues synced")
    end
  end
end
