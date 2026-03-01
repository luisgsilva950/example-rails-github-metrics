# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugs::BuildCategoryCombo do
  subject(:builder) { described_class.new }

  let(:bug) { build(:jira_bug, categories: categories, development_type: dev_type) }
  let(:dev_type) { nil }
  let(:categories) { ["feature:login", "project:auth", "mfe:cw_elements_login"] }

  it "builds combo from matching prefixes" do
    result = builder.call(bug: bug, prefixes: ["feature", "project"])

    expect(result).to eq("feature:login + project:auth")
  end

  it "returns empty string when no prefixes match" do
    result = builder.call(bug: bug, prefixes: ["data_integrity_reason"])

    expect(result).to eq("")
  end

  it "includes development_type when requested" do
    bug.development_type = "Frontend"

    result = builder.call(bug: bug, prefixes: ["feature"], include_dev_type: true)

    expect(result).to eq("feature:login + Frontend")
  end

  it "excludes EXCLUDED_LABELS from matching" do
    bug.categories = ["feature:login", "jira_escalated"]

    result = builder.call(bug: bug, prefixes: ["feature"])

    expect(result).to eq("feature:login")
  end

  it "sorts matched categories within a prefix" do
    bug.categories = ["feature:zebra", "feature:alpha"]

    result = builder.call(bug: bug, prefixes: ["feature"])

    expect(result).to eq("feature:alpha + feature:zebra")
  end
end
