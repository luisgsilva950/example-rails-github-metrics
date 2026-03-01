# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugs::BuildIncrementalJql do
  subject(:service) { described_class.new }

  it "builds JQL without date when last_synced_at is nil" do
    result = service.call(last_synced_at: nil)

    expect(result).to include('project = CWS AND type = Bug')
    expect(result).not_to include("updated >=")
    expect(result).to include("ORDER BY updated DESC")
  end

  it "includes updated >= when last_synced_at is present" do
    time = Time.zone.parse("2026-02-20 14:30:00")
    result = service.call(last_synced_at: time)

    expect(result).to include("updated >= '2026-02-20'")
  end
end
