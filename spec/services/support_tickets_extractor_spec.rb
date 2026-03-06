# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupportTicketsExtractor do
  subject(:extractor) { described_class.new(client: fake_client, jql: jql) }

  let(:jql) { "project = CWS AND type = 'Support Request'" }
  let(:fake_client) { instance_double(JiraClient) }

  def build_issue(key:, title:, status: "Open", priority: "Medium", team: "Digital Farm", assignee: "Dev", reporter: "User")
    fields = {
      "summary" => title,
      "created" => 3.days.ago.iso8601,
      "updated" => 1.day.ago.iso8601,
      "components" => [ { "name" => "Billing" } ],
      "priority" => { "name" => priority },
      "status" => { "name" => status },
      "assignee" => { "name" => assignee },
      "reporter" => { "name" => reporter },
      "description" => "Some description",
      "customfield_10265" => { "value" => team }
    }
    double("Issue", key: key, fields: fields)
  end

  describe "#call" do
    it "creates support tickets from JIRA issues" do
      issue = build_issue(key: "SUP-100", title: "Login broken")
      allow(fake_client).to receive(:search_issues).and_return([ issue ])

      expect { extractor.call }.to change(SupportTicket, :count).by(1)

      ticket = SupportTicket.find_by(issue_key: "SUP-100")
      expect(ticket.title).to eq("Login broken")
      expect(ticket.team).to eq("Digital Farm")
      expect(ticket.components).to eq([ "Billing" ])
    end

    it "updates existing tickets on re-extraction" do
      create(:support_ticket, issue_key: "SUP-200", title: "Old title", status: "Open")
      issue = build_issue(key: "SUP-200", title: "Updated title", status: "In Progress")
      allow(fake_client).to receive(:search_issues).and_return([ issue ])

      expect { extractor.call }.not_to change(SupportTicket, :count)

      ticket = SupportTicket.find_by(issue_key: "SUP-200")
      expect(ticket.title).to eq("Updated title")
      expect(ticket.status).to eq("In Progress")
    end

    it "continues processing when one issue fails" do
      good_issue = build_issue(key: "SUP-300", title: "Good one")
      bad_issue = double("Issue", key: "SUP-BAD", fields: { "summary" => nil, "created" => nil })
      allow(fake_client).to receive(:search_issues).and_return([ bad_issue, good_issue ])

      extractor.call

      expect(SupportTicket.find_by(issue_key: "SUP-300")).to be_present
    end
  end
end
