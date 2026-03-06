# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupportTickets::BuildIncrementalJql do
  subject(:builder) { described_class.new }

  describe "#call" do
    it "builds full sync JQL when last_synced_at is nil" do
      jql = builder.call(last_synced_at: nil)

      expect(jql).to include("type = Support")
      expect(jql).to include("ORDER BY updated DESC")
      expect(jql).to include("updated >=")
    end

    it "includes updated filter when last_synced_at is present" do
      time = Time.zone.parse("2026-03-01 10:00:00")
      jql = builder.call(last_synced_at: time)

      expect(jql).to include("updated >= '2026-03-01'")
      expect(jql).to include("ORDER BY updated DESC")
    end
  end
end
