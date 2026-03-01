# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugs::ListInvalidBugs do
  subject(:service) { described_class.new(jira_base_url: "https://jira.test") }

  let!(:valid_bug) { create(:jira_bug, :with_categories) }
  let!(:missing_project) { create(:jira_bug, :missing_project) }
  let!(:cw_no_mfe) { create(:jira_bug, :cw_elements_without_mfe) }
  let!(:data_integrity) { create(:jira_bug, :data_integrity) }

  it "returns only invalid bugs" do
    result = service.call(scope: JiraBug.done)

    issue_keys = result.map { |b| b[:issue_key] }
    expect(issue_keys).to include(missing_project.issue_key, cw_no_mfe.issue_key)
    expect(issue_keys).not_to include(valid_bug.issue_key, data_integrity.issue_key)
  end

  it "includes reasons for each invalid bug" do
    result = service.call(scope: JiraBug.done)

    missing_proj_result = result.find { |b| b[:issue_key] == missing_project.issue_key }
    expect(missing_proj_result[:reasons]).to include("missing_project_category")
  end

  it "sorts by opened_at descending" do
    result = service.call(scope: JiraBug.done)
    dates = result.map { |b| b[:opened_at] }

    expect(dates).to eq(dates.sort.reverse)
  end

  it "includes jira_link" do
    result = service.call(scope: JiraBug.done)

    expect(result.first[:jira_link]).to start_with("https://jira.test/browse/")
  end
end
