# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugs::GroupBugsByCategory do
  let(:jira_base_url) { "https://example.atlassian.net" }
  subject(:service) { described_class.new(jira_base_url: jira_base_url) }

  it "groups bugs by category with JIRA links" do
    create(:jira_bug, issue_key: "CWS-100", categories: ["feature:login", "project:auth"])
    create(:jira_bug, issue_key: "CWS-101", categories: ["feature:login"])

    result = service.call(scope: JiraBug.done)

    expect(result).to have_key("feature:login")
    expect(result["feature:login"].size).to eq(2)
    expect(result["feature:login"]).to all(include("https://example.atlassian.net/browse/"))
  end

  it "excludes excluded labels" do
    create(:jira_bug, categories: ["feature:login", "jira_escalated"])

    result = service.call(scope: JiraBug.done)

    expect(result).to have_key("feature:login")
    expect(result).not_to have_key("jira_escalated")
  end

  it "returns sorted keys" do
    create(:jira_bug, categories: ["project:z_last"])
    create(:jira_bug, categories: ["feature:a_first"])

    result = service.call(scope: JiraBug.done)

    expect(result.keys).to eq(result.keys.sort)
  end

  it "returns empty hash for no bugs" do
    result = service.call(scope: JiraBug.none)

    expect(result).to eq({})
  end
end
