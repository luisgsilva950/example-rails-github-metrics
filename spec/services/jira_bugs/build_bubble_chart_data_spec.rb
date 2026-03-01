# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugs::BuildBubbleChartData do
  subject(:service) { described_class.new }

  it "returns chart data with x/y positions and radius" do
    create(:jira_bug, categories: ["feature:login"], development_type: "Backend")
    create(:jira_bug, categories: ["feature:login"], development_type: "Backend")
    create(:jira_bug, categories: ["feature:search"], development_type: "Frontend")

    result = service.call(scope: JiraBug.done.where.not(development_type: nil))

    expect(result[:data]).to be_an(Array)
    expect(result[:labels]).to have_key(:x)
    expect(result[:labels]).to have_key(:y)
  end

  it "counts feature occurrences correctly" do
    create(:jira_bug, categories: ["feature:login"], development_type: "Backend")
    create(:jira_bug, categories: ["feature:login"], development_type: "Backend")

    result = service.call(scope: JiraBug.done.where.not(development_type: nil))

    login_point = result[:data].find { |d| d[:feature] == "feature:login" }
    expect(login_point[:count]).to eq(2)
    expect(login_point[:r]).to eq(2)
  end

  it "returns empty data for no bugs" do
    result = service.call(scope: JiraBug.none)

    expect(result[:data]).to be_empty
    expect(result[:labels]).to eq({ x: [], y: [] })
  end
end
