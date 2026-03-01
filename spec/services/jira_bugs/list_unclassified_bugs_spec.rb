# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugs::ListUnclassifiedBugs do
  let(:jira_base_url) { "https://example.atlassian.net" }
  subject(:service) { described_class.new(jira_base_url: jira_base_url) }

  before do
    create(:jira_bug, development_type: nil, components: [])
    create(:jira_bug, development_type: "Backend", components: [ "CW Elements" ])
    create(:jira_bug, development_type: nil, components: [ "Weather" ])
  end

  it "returns bugs without development_type" do
    result = service.call(scope: JiraBug.done, page: 1, size: 25)

    unclassified_keys = result[:content].map { |b| b[:issue_key] }
    no_dev = JiraBug.where(development_type: nil).pluck(:issue_key)
    no_dev.each { |key| expect(unclassified_keys).to include(key) }
  end

  it "paginates results" do
    result = service.call(scope: JiraBug.done, page: 1, size: 1)

    expect(result[:content].size).to eq(1)
    expect(result[:meta][:total]).to be >= 1
    expect(result[:meta][:page]).to eq(1)
  end

  it "returns empty for page beyond range" do
    result = service.call(scope: JiraBug.done, page: 100, size: 25)

    expect(result[:content]).to be_empty
  end
end
