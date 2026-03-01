# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugs::ListAllBugs do
  subject(:service) { described_class.new(jira_base_url: "https://jira.test") }

  let!(:bug1) { create(:jira_bug, :with_categories, status: "10 Done") }
  let!(:bug2) { create(:jira_bug, :missing_project, status: "10 Done") }
  let!(:bug3) { create(:jira_bug, categories: [], status: "01 Open") }

  it "lists all bugs from scope" do
    result = service.call(scope: JiraBug.all)

    expect(result[:total]).to eq(3)
  end

  it "filters by status" do
    result = service.call(scope: JiraBug.all, filters: { status: "10 Done" })

    expect(result[:bugs].map { |b| b[:status] }).to all(eq("10 Done"))
  end

  it "filters no_categories" do
    result = service.call(scope: JiraBug.all, filters: { no_categories: true })

    expect(result[:total]).to eq(1)
    expect(result[:bugs].first[:issue_key]).to eq(bug3.issue_key)
  end

  it "filters by categories_filter" do
    result = service.call(scope: JiraBug.all, filters: { categories_filter: ["feature:login"] })

    result[:bugs].each do |bug|
      expect(bug[:categories]).to include("feature:login")
    end
  end

  it "filters missing_category (excludes bugs that have it)" do
    result = service.call(scope: JiraBug.all, filters: { missing_category: "feature" })

    # Only bug3 (no categories) should remain, as bug1/bug2 have feature:
    expect(result[:bugs].none? { |b| b[:categories].any? { |c| c.start_with?("feature:") } }).to be true
  end

  it "filters feature_without_project" do
    result = service.call(scope: JiraBug.all, filters: { feature_without_project: true })

    expect(result[:total]).to eq(1)
    expect(result[:bugs].first[:issue_key]).to eq(bug2.issue_key)
  end

  it "includes jira_link in results" do
    result = service.call(scope: JiraBug.all)

    expect(result[:bugs].first[:jira_link]).to start_with("https://jira.test/browse/")
  end
end
