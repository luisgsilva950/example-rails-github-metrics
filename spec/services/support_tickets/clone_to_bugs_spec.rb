# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupportTickets::CloneToBugs do
  let(:fake_client) { instance_double(JiraClient) }

  subject(:service) { described_class.new(client: fake_client) }

  let(:ticket) do
    create(:support_ticket,
      title: "Login broken",
      status: "Open",
      priority: "High",
      team: "Digital Farm",
      assignee: "John Doe",
      reporter: "Jane Smith",
      components: %w[Auth Billing],
      description: "Users cannot log in")
  end

  before do
    allow(fake_client).to receive(:create_issue) do |fields:|
      "CWS-#{rand(10_000..99_999)}"
    end
    allow(fake_client).to receive(:link_issues)
  end

  describe "#call" do
    it "creates a bug on JIRA and saves locally" do
      bugs = service.call(ticket_ids: [ ticket.id ])

      expect(fake_client).to have_received(:create_issue)
      expect(bugs.size).to eq(1)
      bug = bugs.first
      expect(bug).to be_persisted
      expect(bug.title).to eq("Login broken")
      expect(bug.priority).to eq("High")
      expect(bug.team).to eq("Digital Farm")
      expect(bug.components).to eq(%w[Auth Billing])
      expect(bug.description).to eq("Users cannot log in")
      expect(bug.issue_type).to eq("Bug")
    end

    it "stores the bug key on the support ticket" do
      allow(fake_client).to receive(:create_issue).and_return("CWS-42")

      service.call(ticket_ids: [ ticket.id ])

      expect(ticket.reload.cloned_to_bug_key).to eq("CWS-42")
    end

    it "sends correct fields to JIRA" do
      service.call(ticket_ids: [ ticket.id ])

      expect(fake_client).to have_received(:create_issue).with(
        fields: hash_including(
          "project" => { "key" => "CWS" },
          "issuetype" => { "name" => "Bug" },
          "summary" => "Login broken",
          "description" => "Users cannot log in",
          "priority" => { "name" => "High" },
          "components" => [ { "name" => "Auth" }, { "name" => "Billing" } ],
          "customfield_10200" => "N/A",
          "customfield_10201" => "N/A",
          "customfield_10202" => "N/A",
          "customfield_10203" => "N/A"
        )
      )
    end

    it "links the bug to the support ticket on JIRA" do
      allow(fake_client).to receive(:create_issue).and_return("CWS-500")

      service.call(ticket_ids: [ ticket.id ])

      expect(fake_client).to have_received(:link_issues).with(
        inward_key: "CWS-500",
        outward_key: ticket.issue_key
      )
    end

    it "sets default values for bug-only fields" do
      bugs = service.call(ticket_ids: [ ticket.id ])
      bug = bugs.first

      expect(bug.categories).to eq([])
      expect(bug.labels).to eq([])
      expect(bug.issue_type).to eq("Bug")
    end

    it "clones multiple tickets" do
      ticket2 = create(:support_ticket, title: "Payments failing")
      bugs = service.call(ticket_ids: [ ticket.id, ticket2.id ])

      expect(bugs.size).to eq(2)
      expect(JiraBug.count).to eq(2)
      expect(fake_client).to have_received(:create_issue).twice
    end

    it "returns empty array when no ids given" do
      expect(service.call(ticket_ids: [])).to eq([])
    end

    it "skips tickets already cloned to bugs" do
      ticket.update!(cloned_to_bug_key: "CWS-999")

      bugs = service.call(ticket_ids: [ ticket.id ])

      expect(bugs).to eq([])
      expect(fake_client).not_to have_received(:create_issue)
    end

    it "clones only new tickets when some are already cloned" do
      ticket.update!(cloned_to_bug_key: "CWS-999")
      ticket2 = create(:support_ticket, title: "New ticket")

      bugs = service.call(ticket_ids: [ ticket.id, ticket2.id ])

      expect(bugs.size).to eq(1)
      expect(bugs.first.title).to eq("New ticket")
      expect(fake_client).to have_received(:create_issue).once
    end
  end
end
