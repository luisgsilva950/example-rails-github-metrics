# frozen_string_literal: true

require "rails_helper"

RSpec.describe SonarIssue do
  describe "validations" do
    it "requires issue_key" do
      issue = build(:sonar_issue, issue_key: nil)

      expect(issue).not_to be_valid
      expect(issue.errors[:issue_key]).to include("can't be blank")
    end

    it "requires issue_type" do
      issue = build(:sonar_issue, issue_type: nil)

      expect(issue).not_to be_valid
      expect(issue.errors[:issue_type]).to include("can't be blank")
    end

    it "requires unique issue_key within the same project" do
      project = create(:sonar_project)
      create(:sonar_issue, issue_key: "AXyz-dup", sonar_project: project)
      dup = build(:sonar_issue, issue_key: "AXyz-dup", sonar_project: project)

      expect(dup).not_to be_valid
    end

    it "allows same issue_key across different projects" do
      project_a = create(:sonar_project, sonar_key: "org:proj-a", name: "Project A")
      project_b = create(:sonar_project, sonar_key: "org:proj-b", name: "Project B")
      create(:sonar_issue, issue_key: "AXyz-shared", sonar_project: project_a)
      dup = build(:sonar_issue, issue_key: "AXyz-shared", sonar_project: project_b)

      expect(dup).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a sonar_project" do
      issue = create(:sonar_issue)

      expect(issue.sonar_project).to be_a(SonarProject)
    end
  end

  describe "scopes" do
    let!(:project) { create(:sonar_project) }
    let!(:bug) { create(:sonar_issue, sonar_project: project, issue_type: "BUG") }
    let!(:vuln) { create(:sonar_issue, sonar_project: project, issue_type: "VULNERABILITY") }
    let!(:smell) { create(:sonar_issue, sonar_project: project, issue_type: "CODE_SMELL") }
    let!(:hotspot) { create(:sonar_issue, sonar_project: project, issue_type: "SECURITY_HOTSPOT") }

    it ".bugs returns only BUG type" do
      expect(described_class.bugs).to contain_exactly(bug)
    end

    it ".vulnerabilities returns only VULNERABILITY type" do
      expect(described_class.vulnerabilities).to contain_exactly(vuln)
    end

    it ".code_smells returns only CODE_SMELL type" do
      expect(described_class.code_smells).to contain_exactly(smell)
    end

    it ".security_hotspots returns only SECURITY_HOTSPOT type" do
      expect(described_class.security_hotspots).to contain_exactly(hotspot)
    end

    it ".by_severity filters by severity" do
      critical = create(:sonar_issue, sonar_project: project, severity: "CRITICAL")

      expect(described_class.by_severity("CRITICAL")).to contain_exactly(critical)
    end

    it ".by_status filters by status" do
      closed = create(:sonar_issue, sonar_project: project, status: "CLOSED")

      expect(described_class.by_status("CLOSED")).to contain_exactly(closed)
    end

    it ".open returns OPEN, CONFIRMED, REOPENED statuses" do
      open_issue = create(:sonar_issue, sonar_project: project, status: "OPEN")
      confirmed = create(:sonar_issue, sonar_project: project, status: "CONFIRMED")
      create(:sonar_issue, sonar_project: project, status: "CLOSED")

      expect(described_class.open).to contain_exactly(bug, vuln, smell, hotspot, open_issue, confirmed)
    end

    it ".resolved returns CLOSED, RESOLVED, FIXED, WONTFIX statuses" do
      closed = create(:sonar_issue, sonar_project: project, status: "CLOSED")
      resolved = create(:sonar_issue, sonar_project: project, status: "RESOLVED")
      fixed = create(:sonar_issue, sonar_project: project, status: "FIXED")
      wontfix = create(:sonar_issue, sonar_project: project, status: "WONTFIX")
      create(:sonar_issue, sonar_project: project, status: "OPEN")

      expect(described_class.resolved).to contain_exactly(closed, resolved, fixed, wontfix)
    end

    it ".critical_or_blocker returns CRITICAL and BLOCKER severities" do
      critical = create(:sonar_issue, sonar_project: project, severity: "CRITICAL")
      blocker = create(:sonar_issue, sonar_project: project, severity: "BLOCKER")
      create(:sonar_issue, sonar_project: project, severity: "MAJOR")

      expect(described_class.critical_or_blocker).to contain_exactly(critical, blocker)
    end

    it ".critical_counts_by_project counts open CRITICAL and BLOCKER issues" do
      create(:sonar_issue, sonar_project: project, severity: "CRITICAL", issue_type: "BUG", status: "OPEN")
      create(:sonar_issue, sonar_project: project, severity: "BLOCKER", issue_type: "BUG", status: "OPEN")
      create(:sonar_issue, sonar_project: project, severity: "CRITICAL", issue_type: "BUG", status: "CLOSED")
      create(:sonar_issue, sonar_project: project, severity: "MAJOR", issue_type: "BUG", status: "OPEN")

      counts = described_class.critical_counts_by_project
      key = [ project.id, "BUG" ]
      expect(counts[key]).to eq(2)
    end
  end
end
