# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Metrics::SupportTickets", type: :request do
  let(:team) { "Digital Farm" }
  let(:today) { Time.current.in_time_zone(SupportTicket::SAO_PAULO_TZ).to_date }

  before do
    create(:support_ticket, team: team, opened_at: today - 5.days, status: "Open", priority: "High")
    create(:support_ticket, team: team, opened_at: today - 3.days, status: "In Progress", priority: "Medium")
    create(:support_ticket, team: team, opened_at: today - 1.day, status: "Closed", priority: "Low")
  end

  describe "GET /metrics/support_tickets" do
    it "renders the support tickets page" do
      get "/metrics/support_tickets", params: {
        team: team,
        start_date: (today - 30.days).iso8601,
        end_date: today.iso8601
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Support Tickets")
      expect(response.body).to include("SUP-")
    end

    it "shows total ticket count" do
      get "/metrics/support_tickets", params: { team: team }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("3")
    end

    it "filters by status" do
      get "/metrics/support_tickets", params: {
        team: team,
        start_date: (today - 30.days).iso8601,
        end_date: today.iso8601,
        status: "Open"
      }

      expect(response).to have_http_status(:ok)
    end

    it "filters by priority" do
      get "/metrics/support_tickets", params: {
        team: team,
        start_date: (today - 30.days).iso8601,
        end_date: today.iso8601,
        priority: "High"
      }

      expect(response).to have_http_status(:ok)
    end

    it "shows empty state when no tickets match" do
      get "/metrics/support_tickets", params: { team: "Nonexistent Team" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No support tickets found")
    end

    it "defaults team to Digital Farm" do
      get "/metrics/support_tickets"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("SUP-")
    end
  end

  describe "POST /metrics/support_tickets/clone_to_bugs" do
    let(:fake_client) { instance_double(JiraClient) }

    before do
      allow(JiraClient).to receive(:new).and_return(fake_client)
      allow(fake_client).to receive(:create_issue) do |fields:|
        "CWS-#{rand(10_000..99_999)}"
      end
      allow(fake_client).to receive(:link_issues)
    end

    it "clones selected tickets to jira bugs via JIRA API" do
      tickets = SupportTicket.all

      post "/metrics/support_tickets/clone_to_bugs",
        params: { ticket_ids: tickets.map(&:id) }

      expect(response).to redirect_to(metrics_support_tickets_path)
      follow_redirect!
      expect(response.body).to include("3 ticket(s) cloned to bugs")
      expect(JiraBug.count).to eq(3)
      expect(fake_client).to have_received(:create_issue).exactly(3).times
    end

    it "redirects back with zero count when no ids given" do
      post "/metrics/support_tickets/clone_to_bugs", params: { ticket_ids: [] }

      expect(response).to redirect_to(metrics_support_tickets_path)
      follow_redirect!
      expect(response.body).to include("0 ticket(s) cloned to bugs")
    end
  end
end
