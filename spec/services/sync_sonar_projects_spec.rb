# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncSonarProjects do
  describe "#call" do
    let(:fake_client) { instance_double(SonarCloudClient) }

    subject(:service) { described_class.new(client: fake_client) }

    it "creates new projects from API response" do
      allow(fake_client).to receive(:projects).with(page: 1).and_return(
        "paging" => { "total" => 1 },
        "components" => [ {
          "key" => "org_new-repo",
          "name" => "new-repo",
          "qualifier" => "TRK",
          "visibility" => "private",
          "lastAnalysisDate" => "2026-03-20T10:00:00+0000"
        } ]
      )

      expect { service.call }.to change(SonarProject, :count).by(1)

      project = SonarProject.find_by(sonar_key: "org_new-repo")
      expect(project.name).to eq("new-repo")
      expect(project.qualifier).to eq("TRK")
    end

    it "updates existing projects" do
      create(:sonar_project, sonar_key: "org_existing", name: "old-name")

      allow(fake_client).to receive(:projects).with(page: 1).and_return(
        "paging" => { "total" => 1 },
        "components" => [ {
          "key" => "org_existing",
          "name" => "new-name",
          "qualifier" => "TRK",
          "visibility" => "public"
        } ]
      )

      expect { service.call }.not_to change(SonarProject, :count)

      expect(SonarProject.find_by(sonar_key: "org_existing").name).to eq("new-name")
    end

    it "paginates through all projects" do
      allow(fake_client).to receive(:projects).with(page: 1).and_return(
        "paging" => { "total" => 2 },
        "components" => [ { "key" => "org_repo1", "name" => "repo1", "qualifier" => "TRK" } ]
      )
      allow(fake_client).to receive(:projects).with(page: 2).and_return(
        "paging" => { "total" => 2 },
        "components" => [ { "key" => "org_repo2", "name" => "repo2", "qualifier" => "TRK" } ]
      )

      expect(service.call).to eq(2)
      expect(SonarProject.count).to eq(2)
    end

    it "returns total synced count" do
      allow(fake_client).to receive(:projects).with(page: 1).and_return(
        "paging" => { "total" => 0 },
        "components" => []
      )

      expect(service.call).to eq(0)
    end
  end
end
