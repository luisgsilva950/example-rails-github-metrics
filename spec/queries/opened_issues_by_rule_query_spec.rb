# frozen_string_literal: true

require "rails_helper"

RSpec.describe OpenedIssuesByRuleQuery do
  describe "#call" do
    it "groups issues by rule and then by project name with file paths" do
      project_a = create(:sonar_project, name: "alpha-service")
      project_b = create(:sonar_project, name: "beta-service")
      create(:sonar_issue, sonar_project: project_a, rule: "java:S1234", component: "alpha:src/Foo.java", issue_key: "A1")
      create(:sonar_issue, sonar_project: project_b, rule: "java:S1234", component: "beta:src/Bar.java", issue_key: "B1")

      result = described_class.new.call

      expect(result["java:S1234"].keys).to contain_exactly("alpha-service", "beta-service")
      expect(result["java:S1234"]["alpha-service"]).to eq([ "src/Foo.java" ])
      expect(result["java:S1234"]["beta-service"]).to eq([ "src/Bar.java" ])
    end

    it "strips the component key prefix from file paths" do
      project = create(:sonar_project, name: "my-repo")
      create(:sonar_issue, sonar_project: project, rule: "java:S1000", component: "org_my-repo:src/main/App.java")

      result = described_class.new.call

      expect(result["java:S1000"]["my-repo"]).to eq([ "src/main/App.java" ])
    end

    it "deduplicates file paths within a project" do
      project = create(:sonar_project, name: "my-repo")
      create(:sonar_issue, sonar_project: project, rule: "java:S1000", component: "org:src/Foo.java", issue_key: "D1")
      create(:sonar_issue, sonar_project: project, rule: "java:S1000", component: "org:src/Foo.java", issue_key: "D2")

      result = described_class.new.call

      expect(result["java:S1000"]["my-repo"]).to eq([ "src/Foo.java" ])
    end

    it "excludes resolved issues" do
      project = create(:sonar_project, name: "my-repo")
      create(:sonar_issue, sonar_project: project, rule: "java:S1000", status: "OPEN", issue_key: "O1")
      create(:sonar_issue, sonar_project: project, rule: "java:S2000", status: "CLOSED", issue_key: "C1")

      result = described_class.new.call

      expect(result.keys).to eq([ "java:S1000" ])
    end

    it "respects a custom scope" do
      project = create(:sonar_project, name: "my-repo")
      create(:sonar_issue, sonar_project: project, rule: "java:S1000", severity: "CRITICAL", status: "OPEN", issue_key: "CR1")
      create(:sonar_issue, sonar_project: project, rule: "java:S2000", severity: "MAJOR", status: "OPEN", issue_key: "MJ1")

      result = described_class.new(scope: SonarIssue.open.critical_or_blocker).call

      expect(result.keys).to eq([ "java:S1000" ])
    end
  end
end
