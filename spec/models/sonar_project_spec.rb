# frozen_string_literal: true

require "rails_helper"

RSpec.describe SonarProject do
  describe "validations" do
    it "requires sonar_key" do
      project = build(:sonar_project, sonar_key: nil)

      expect(project).not_to be_valid
      expect(project.errors[:sonar_key]).to include("can't be blank")
    end

    it "requires name" do
      project = build(:sonar_project, name: nil)

      expect(project).not_to be_valid
      expect(project.errors[:name]).to include("can't be blank")
    end

    it "requires unique sonar_key" do
      create(:sonar_project, sonar_key: "org_repo-dup")
      dup = build(:sonar_project, sonar_key: "org_repo-dup")

      expect(dup).not_to be_valid
    end
  end

  describe "associations" do
    it "has many sonar_issues" do
      project = create(:sonar_project)
      create(:sonar_issue, sonar_project: project)

      expect(project.sonar_issues.count).to eq(1)
    end

    it "destroys associated issues on delete" do
      project = create(:sonar_project)
      create(:sonar_issue, sonar_project: project)

      expect { project.destroy }.to change(SonarIssue, :count).by(-1)
    end
  end

  describe "scopes" do
    it ".by_name orders alphabetically" do
      create(:sonar_project, name: "zebra")
      create(:sonar_project, name: "alpha")

      expect(described_class.by_name.pluck(:name)).to eq(%w[alpha zebra])
    end

    it ".ordered_by_bugs orders by bugs descending" do
      low = create(:sonar_project, bugs: 1)
      high = create(:sonar_project, bugs: 10)

      expect(described_class.ordered_by_bugs).to eq([ high, low ])
    end

    it ".ordered_by_coverage orders by coverage ascending" do
      high = create(:sonar_project, coverage: 90.0)
      low = create(:sonar_project, coverage: 20.0)

      expect(described_class.ordered_by_coverage).to eq([ low, high ])
    end

    it ".with_critical_issues returns only projects that have critical issues" do
      with_critical = create(:sonar_project, name: "critical-repo")
      without_critical = create(:sonar_project, name: "clean-repo")
      create(:sonar_issue, sonar_project: with_critical, severity: "CRITICAL")
      create(:sonar_issue, sonar_project: without_critical, severity: "MAJOR")

      result = described_class.with_critical_issues

      expect(result).to contain_exactly(with_critical)
    end

    it ".with_critical_issues returns distinct projects" do
      project = create(:sonar_project)
      create(:sonar_issue, sonar_project: project, severity: "CRITICAL", issue_key: "K1")
      create(:sonar_issue, sonar_project: project, severity: "CRITICAL", issue_key: "K2")

      expect(described_class.with_critical_issues.count).to eq(1)
    end
  end
end
