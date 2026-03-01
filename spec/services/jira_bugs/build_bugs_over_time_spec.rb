# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugs::BuildBugsOverTime do
  subject(:service) { described_class.new }

  let!(:bug1) { create(:jira_bug, :with_feature, opened_at: "2026-01-05 12:00:00") }
  let!(:bug2) { create(:jira_bug, :with_feature, opened_at: "2026-01-06 12:00:00") }
  let!(:bug3) { create(:jira_bug, categories: ["feature:signup", "project:auth"], opened_at: "2026-01-12 12:00:00") }
  let(:scope) { JiraBug.done }

  describe "total mode (no group_by_category)" do
    it "returns time-bucketed counts" do
      result = service.call(scope: scope, group_by: "weekly")

      expect(result[:chart_values]).to be_present
      expect(result[:total_bugs]).to eq(3)
      expect(result[:chart_datasets]).to be_nil
      expect(result[:pie_data]).to be_nil
    end

    it "returns display labels matching chart labels" do
      result = service.call(scope: scope, group_by: "weekly")

      expect(result[:display_labels].size).to eq(result[:chart_labels].size)
    end
  end

  describe "categorized mode (with group_by_category)" do
    it "groups by category combination" do
      result = service.call(scope: scope, group_by: "weekly", group_by_category: "feature")

      expect(result[:chart_datasets]).to be_present
      expect(result[:pie_data]).to be_present
      expect(result[:chart_values]).to be_nil
    end

    it "respects top_n limit" do
      result = service.call(scope: scope, group_by: "weekly", group_by_category: "feature", top_n: 1)

      expect(result[:chart_datasets].size).to eq(1)
      expect(result[:pie_data].size).to eq(1)
    end

    it "includes sub_category in combo when provided" do
      result = service.call(scope: scope, group_by: "weekly", group_by_category: "feature", sub_category: "project")

      dataset_names = result[:chart_datasets].map { |ds| ds[:name] }
      expect(dataset_names).to all(include("project:"))
    end
  end
end
