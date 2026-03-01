# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugs::BuildCategoryAnalysis do
  subject(:service) { described_class.new }

  let!(:bug1) { create(:jira_bug, categories: [ "feature:login", "project:auth" ]) }
  let!(:bug2) { create(:jira_bug, categories: [ "feature:login", "project:auth" ]) }
  let!(:bug3) { create(:jira_bug, categories: [ "feature:signup", "project:identity" ]) }
  let(:scope) { JiraBug.done }

  it "groups and counts by category combo" do
    result = service.call(scope: scope, category_types: [ "feature" ])

    expect(result[:chart_labels]).to include("feature:login", "feature:signup")
    expect(result[:total_bugs]).to eq(3)
  end

  it "combines multiple prefixes into combos" do
    result = service.call(scope: scope, category_types: [ "feature", "project" ])

    expect(result[:chart_labels].first).to include("+")
  end

  it "sorts by count descending" do
    result = service.call(scope: scope, category_types: [ "feature" ])

    expect(result[:chart_values]).to eq(result[:chart_values].sort.reverse)
  end

  it "includes development_type when requested" do
    bug1.update!(development_type: "Frontend")

    result = service.call(scope: scope, category_types: [ "feature", "development_type" ])

    frontend_combos = result[:chart_labels].select { |l| l.include?("Frontend") }
    expect(frontend_combos).to be_present
  end
end
