# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncSonarIssues do
  describe "#call" do
    let(:fake_client) { instance_double(SonarCloudClient) }
    let(:project) { create(:sonar_project, sonar_key: "org_repo") }

    subject(:service) { described_class.new(client: fake_client) }

    it "creates new issues from API response" do
      allow(fake_client).to receive(:issues).with(component_key: "org_repo", page: 1, created_after: nil).and_return(
        "paging" => { "total" => 1 },
        "issues" => [ {
          "key" => "AXyz123",
          "type" => "BUG",
          "severity" => "MAJOR",
          "status" => "OPEN",
          "rule" => "java:S1234",
          "message" => "Fix null pointer",
          "component" => "org_repo:src/main.rb",
          "line" => 42,
          "effort" => "15min",
          "creationDate" => "2026-03-20T10:00:00+0000",
          "updateDate" => "2026-03-21T10:00:00+0000",
          "tags" => [ "bug", "critical" ]
        } ]
      )

      expect { service.call(project: project) }.to change(SonarIssue, :count).by(1)

      issue = SonarIssue.find_by(issue_key: "AXyz123")
      expect(issue.issue_type).to eq("BUG")
      expect(issue.severity).to eq("MAJOR")
      expect(issue.rule).to eq("java:S1234")
      expect(issue.tags).to eq([ "bug", "critical" ])
    end

    it "updates existing issues" do
      create(:sonar_issue, sonar_project: project, issue_key: "AXyz-existing", status: "OPEN")

      allow(fake_client).to receive(:issues).with(component_key: "org_repo", page: 1, created_after: nil).and_return(
        "paging" => { "total" => 1 },
        "issues" => [ {
          "key" => "AXyz-existing",
          "type" => "BUG",
          "severity" => "MAJOR",
          "status" => "CLOSED",
          "message" => "Fixed",
          "tags" => []
        } ]
      )

      expect { service.call(project: project) }.not_to change(SonarIssue, :count)

      expect(SonarIssue.find_by(issue_key: "AXyz-existing").status).to eq("CLOSED")
    end

    it "paginates through all issues" do
      allow(fake_client).to receive(:issues).with(component_key: "org_repo", page: 1, created_after: nil).and_return(
        "paging" => { "total" => 2 },
        "issues" => [ { "key" => "A1", "type" => "BUG", "severity" => "MAJOR", "status" => "OPEN", "tags" => [] } ]
      )
      allow(fake_client).to receive(:issues).with(component_key: "org_repo", page: 2, created_after: nil).and_return(
        "paging" => { "total" => 2 },
        "issues" => [ { "key" => "A2", "type" => "CODE_SMELL", "severity" => "MINOR", "status" => "OPEN", "tags" => [] } ]
      )

      expect(service.call(project: project)).to eq(2)
    end

    it "returns total synced count" do
      allow(fake_client).to receive(:issues).with(component_key: "org_repo", page: 1, created_after: nil).and_return(
        "paging" => { "total" => 0 },
        "issues" => []
      )

      expect(service.call(project: project)).to eq(0)
    end

    it "updates issues_synced_at on the project after sync" do
      allow(fake_client).to receive(:issues).with(component_key: "org_repo", page: 1, created_after: nil).and_return(
        "paging" => { "total" => 0 },
        "issues" => []
      )

      expect(project.issues_synced_at).to be_nil

      service.call(project: project)

      expect(project.reload.issues_synced_at).to be_within(2.seconds).of(Time.current)
    end

    it "passes since as created_after to the client" do
      since = 6.hours.ago

      allow(fake_client).to receive(:issues).with(component_key: "org_repo", page: 1, created_after: since).and_return(
        "paging" => { "total" => 1 },
        "issues" => [ { "key" => "NEW1", "type" => "BUG", "severity" => "MINOR", "status" => "OPEN", "tags" => [] } ]
      )

      service.call(project: project, since: since)

      expect(fake_client).to have_received(:issues).with(component_key: "org_repo", page: 1, created_after: since)
    end
  end
end
