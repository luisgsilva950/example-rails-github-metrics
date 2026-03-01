# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraClient do
  let(:jira_client_mock) { instance_double(JIRA::Client) }
  let(:issue_resource) { double("IssueResource") }

  before do
    allow(JIRA::Client).to receive(:new).and_return(jira_client_mock)
    allow(jira_client_mock).to receive(:Issue).and_return(issue_resource)
  end

  subject(:client) do
    described_class.new(site: "https://jira.example.com", username: "user", api_token: "token")
  end

  describe "#initialize" do
    it "creates a client with provided options" do
      expect(client).to be_a(JiraClient)
    end

    it "reads verify_ssl from ENV" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("JIRA_VERIFY_SSL", "true").and_return("false")

      c = described_class.new(site: "https://jira.example.com", username: "user", api_token: "token")
      expect(c).to be_a(JiraClient)
    end

    it "disables SSL verification when verify_ssl is false" do
      expect(Rails.logger).to receive(:warn).with(/SSL verification DESATIVADA/)

      described_class.new(
        site: "https://jira.example.com",
        username: "user",
        api_token: "token",
        verify_ssl: false
      )
    end
  end

  describe "#search_issues" do
    let(:issue1) { double("Issue", id: "1001", key: "TEST-1") }
    let(:issue2) { double("Issue", id: "1002", key: "TEST-2") }
    let(:full_issue1) { double("FullIssue", key: "TEST-1") }
    let(:full_issue2) { double("FullIssue", key: "TEST-2") }

    it "returns issues from JQL query with fetch_full" do
      allow(issue_resource).to receive(:jql).and_return([issue1, issue2])
      allow(issue_resource).to receive(:find).with("1001").and_return(full_issue1)
      allow(issue_resource).to receive(:find).with("1002").and_return(full_issue2)

      result = client.search_issues("project = TEST", fetch_full: true)

      expect(result).to eq([full_issue1, full_issue2])
    end

    it "returns issues without fetch_full" do
      allow(issue_resource).to receive(:jql).and_return([issue1, issue2])

      result = client.search_issues("project = TEST", fetch_full: false)

      expect(result).to eq([issue1, issue2])
    end

    it "returns empty array on error" do
      allow(issue_resource).to receive(:jql).and_raise(StandardError.new("API error"))
      allow(Rails.logger).to receive(:error)

      result = client.search_issues("project = TEST")

      expect(result).to eq([])
    end

    it "handles fetch_full from ENV" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("JIRA_FETCH_FULL", "true").and_return("false")
      allow(issue_resource).to receive(:jql).and_return([issue1])

      result = client.search_issues("project = TEST")

      expect(result).to eq([issue1])
    end

    it "accepts custom fields and expand" do
      allow(issue_resource).to receive(:jql).and_return([])

      result = client.search_issues("project = TEST", fields: "summary", expand: "changelog", fetch_full: false)

      expect(result).to eq([])
    end
  end

  describe "#fetch_issue" do
    it "returns the fetched issue" do
      issue = double("Issue", key: "TEST-1")
      allow(issue_resource).to receive(:find).with("TEST-1").and_return(issue)

      result = client.fetch_issue("TEST-1")

      expect(result).to eq(issue)
    end

    it "returns nil on error" do
      allow(issue_resource).to receive(:find).and_raise(StandardError.new("Not found"))
      allow(Rails.logger).to receive(:error)

      result = client.fetch_issue("TEST-999")

      expect(result).to be_nil
    end

    it "accepts fields and expand options" do
      issue = double("Issue", key: "TEST-1")
      allow(issue_resource).to receive(:find).with("TEST-1").and_return(issue)

      result = client.fetch_issue("TEST-1", fields: "summary", expand: "changelog")

      expect(result).to eq(issue)
    end
  end
end
