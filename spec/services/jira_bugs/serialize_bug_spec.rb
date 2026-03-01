# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugs::SerializeBug do
  subject(:serializer) { described_class.new(jira_base_url: "https://jira.test") }

  let(:bug) do
    build(:jira_bug,
      issue_key: "CWS-999",
      title: "Test bug",
      categories: [ "feature:login", "jira_escalated" ],
      development_type: "Frontend",
      components: [ "My Cropwise" ],
      opened_at: Time.zone.parse("2026-01-15 10:00:00")
    )
  end

  it "serializes bug with correct keys" do
    result = serializer.call(bug)

    expect(result).to include(
      issue_key: "CWS-999",
      title: "Test bug",
      development_type: "Frontend"
    )
  end

  it "builds correct jira_link" do
    result = serializer.call(bug)

    expect(result[:jira_link]).to eq("https://jira.test/browse/CWS-999")
  end

  it "filters excluded labels from categories" do
    result = serializer.call(bug)

    expect(result[:categories]).to eq([ "feature:login" ])
    expect(result[:categories]).not_to include("jira_escalated")
  end
end
