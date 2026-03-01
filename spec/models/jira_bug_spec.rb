# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBug do
  describe "validations" do
    it "requires issue_key" do
      bug = build(:jira_bug, issue_key: nil)
      expect(bug).not_to be_valid
    end

    it "requires title" do
      bug = build(:jira_bug, title: nil)
      expect(bug).not_to be_valid
    end

    it "requires opened_at" do
      bug = build(:jira_bug, opened_at: nil)
      expect(bug).not_to be_valid
    end

    it "requires unique issue_key" do
      create(:jira_bug, issue_key: "CWS-DUP")
      dup = build(:jira_bug, issue_key: "CWS-DUP")
      expect(dup).not_to be_valid
    end
  end

  describe "development_type enum" do
    it "accepts Backend" do
      bug = build(:jira_bug, development_type: "Backend")
      expect(bug).to be_valid
      expect(bug).to be_Backend
    end

    it "accepts Frontend" do
      bug = build(:jira_bug, development_type: "Frontend")
      expect(bug).to be_valid
      expect(bug).to be_Frontend
    end

    it "accepts nil (optional)" do
      bug = build(:jira_bug, development_type: nil)
      expect(bug).to be_valid
    end

    it "rejects invalid values" do
      bug = build(:jira_bug, development_type: "Sustaining")
      expect(bug).not_to be_valid
      expect(bug.errors[:development_type]).to be_present
    end
  end

  describe ".done" do
    it "returns bugs with status '10 Done'" do
      done_bug = create(:jira_bug, status: "10 Done")
      create(:jira_bug, :open)

      expect(described_class.done).to contain_exactly(done_bug)
    end
  end

  describe ".by_date_range" do
    let!(:old_bug) { create(:jira_bug, opened_at: "2025-06-01 12:00:00") }
    let!(:recent_bug) { create(:jira_bug, opened_at: "2026-01-15 12:00:00") }

    it "filters by start_date" do
      result = described_class.by_date_range("2026-01-01", nil)

      expect(result).to contain_exactly(recent_bug)
    end

    it "filters by end_date" do
      result = described_class.by_date_range(nil, "2025-12-31")

      expect(result).to contain_exactly(old_bug)
    end

    it "filters by both dates" do
      result = described_class.by_date_range("2026-01-01", "2026-12-31")

      expect(result).to contain_exactly(recent_bug)
    end
  end

  describe ".with_category_prefix" do
    let!(:feature_bug) { create(:jira_bug, categories: [ "feature:login" ]) }
    let!(:project_bug) { create(:jira_bug, categories: [ "project:auth" ]) }

    it "returns bugs with matching prefix" do
      result = described_class.with_category_prefix("feature")

      expect(result).to contain_exactly(feature_bug)
    end
  end

  describe ".filter_categories" do
    it "removes excluded labels" do
      categories = [ "feature:login", "jira_escalated", "Failure", "delayed", "project:auth" ]

      result = described_class.filter_categories(categories)

      expect(result).to eq([ "feature:login", "project:auth" ])
    end

    it "handles nil input" do
      expect(described_class.filter_categories(nil)).to eq([])
    end
  end
end
