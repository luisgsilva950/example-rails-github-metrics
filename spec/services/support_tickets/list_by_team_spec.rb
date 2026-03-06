# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupportTickets::ListByTeam do
  subject(:service) { described_class.new(jira_base_url: jira_base_url) }

  let(:jira_base_url) { "https://example.atlassian.net" }
  let(:team) { "Digital Farm" }

  describe "#call" do
    it "returns tickets ordered by most recent" do
      old = create(:support_ticket, team: team, opened_at: 10.days.ago)
      recent = create(:support_ticket, team: team, opened_at: 1.day.ago)

      result = service.call(scope: SupportTicket.by_team(team))

      expect(result[:tickets].map { |t| t[:issue_key] }).to eq([ recent.issue_key, old.issue_key ])
      expect(result[:total]).to eq(2)
    end

    it "serializes tickets with jira_link" do
      ticket = create(:support_ticket, team: team)

      result = service.call(scope: SupportTicket.by_team(team))

      serialized = result[:tickets].first
      expect(serialized[:jira_link]).to eq("#{jira_base_url}/browse/#{ticket.issue_key}")
      expect(serialized[:issue_key]).to eq(ticket.issue_key)
      expect(serialized[:title]).to eq(ticket.title)
      expect(serialized[:status]).to eq(ticket.status)
      expect(serialized[:priority]).to eq(ticket.priority)
      expect(serialized[:team]).to eq(ticket.team)
      expect(serialized[:cloned_to_bug_key]).to be_nil
    end

    it "includes cloned_to_bug_key when ticket was cloned" do
      ticket = create(:support_ticket, team: team, cloned_to_bug_key: "CWS-123")

      result = service.call(scope: SupportTicket.by_team(team))

      expect(result[:tickets].first[:cloned_to_bug_key]).to eq("CWS-123")
    end

    it "filters by status" do
      create(:support_ticket, team: team, status: "Open")
      create(:support_ticket, team: team, status: "Closed")

      result = service.call(scope: SupportTicket.by_team(team), filters: { status: "Open" })

      expect(result[:total]).to eq(1)
      expect(result[:tickets].first[:status]).to eq("Open")
    end

    it "filters by priority" do
      create(:support_ticket, team: team, priority: "High")
      create(:support_ticket, team: team, priority: "Low")

      result = service.call(scope: SupportTicket.by_team(team), filters: { priority: "High" })

      expect(result[:total]).to eq(1)
      expect(result[:tickets].first[:priority]).to eq("High")
    end

    it "returns empty when no tickets match" do
      result = service.call(scope: SupportTicket.by_team(team))

      expect(result[:tickets]).to be_empty
      expect(result[:total]).to eq(0)
    end
  end
end
