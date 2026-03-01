# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugsExtractor do
  subject(:extractor) { described_class.new(client: client, jql: "project = TEST", max_results: 100) }

  let(:client) { instance_double(JiraClient) }

  def build_issue(key:, fields: {})
    default_fields = {
      "summary" => "Bug title for #{key}",
      "created" => "2025-12-01T10:00:00.000+0000",
      "updated" => "2025-12-02T10:00:00.000+0000",
      "components" => [ { "name" => "Weather" } ],
      "labels" => [ "feature:login" ],
      "priority" => { "name" => "High" },
      "issuetype" => { "name" => "Bug" },
      "reporter" => { "displayName" => "Jane Doe" },
      "status" => { "name" => "10 Done" },
      "assignee" => { "name" => "john.doe" },
      "description" => "A description",
      "customfield_10265" => { "value" => "Digital Farm" },
      "customfield_10300" => nil,
      "customfield_10249" => "Root cause text",
      "customfield_10735" => { "value" => "Backend" },
      "comment" => {
        "comments" => [
          { "author" => { "displayName" => "Commenter" }, "body" => "A comment", "created" => "2025-12-01T11:00:00.000+0000", "updated" => "2025-12-01T11:00:00.000+0000" }
        ]
      }
    }.merge(fields)

    issue = double("JiraIssue", key: key, fields: default_fields)
    issue
  end

  describe "#call" do
    it "searches issues and saves them" do
      issues = [ build_issue(key: "TEST-1"), build_issue(key: "TEST-2") ]
      allow(client).to receive(:search_issues).and_return(issues)
      allow(client).to receive(:fetch_issue).and_return(nil)

      expect { extractor.call }.to change(JiraBug, :count).by(2)
    end
  end

  describe "#save_issues" do
    it "creates new JiraBug records" do
      issue = build_issue(key: "TEST-100")
      allow(client).to receive(:fetch_issue).and_return(nil)

      expect { extractor.save_issues([ issue ]) }.to change(JiraBug, :count).by(1)

      bug = JiraBug.find_by(issue_key: "TEST-100")
      expect(bug.title).to eq("Bug title for TEST-100")
      expect(bug.priority).to eq("High")
      expect(bug.team).to eq("Digital Farm")
      expect(bug.status).to eq("10 Done")
      expect(bug.assignee).to eq("john.doe")
      expect(bug.components).to eq([ "Weather" ])
      expect(bug.root_cause_analysis).to eq("Root cause text")
      expect(bug.development_type).to eq("Backend")
      expect(bug.comments_count).to eq(1)
    end

    it "updates existing JiraBug records" do
      create(:jira_bug, issue_key: "TEST-200", title: "Old title")
      issue = build_issue(key: "TEST-200", fields: { "summary" => "New title" })
      allow(client).to receive(:fetch_issue).and_return(nil)

      expect { extractor.save_issues([ issue ]) }.not_to change(JiraBug, :count)

      bug = JiraBug.find_by(issue_key: "TEST-200")
      expect(bug.title).to eq("New title")
    end

    it "logs and continues on save failure" do
      issue = build_issue(key: "TEST-ERR", fields: { "summary" => nil })
      allow(client).to receive(:fetch_issue).and_return(nil)

      expect(Rails.logger).to receive(:error).with(/Falha ao salvar issue/)

      extractor.save_issues([ issue ])
    end

    it "normalizes categories via CategoriesNormalizer" do
      issue = build_issue(key: "TEST-CAT", fields: { "labels" => [ "cw_elements_button" ] })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-CAT")
      expect(bug.categories).to include("mfe:cw_elements_button")
    end

    it "updates JIRA labels when normalization changes categories" do
      issue = build_issue(key: "TEST-SYNC", fields: { "labels" => [ "cw_elements_button" ] })
      jira_issue = double("JiraIssue")
      allow(client).to receive(:fetch_issue).with("TEST-SYNC").and_return(jira_issue)
      allow(jira_issue).to receive(:save)

      extractor.save_issues([ issue ])

      expect(jira_issue).to have_received(:save).with(hash_including("fields"))
    end

    it "handles JIRA update failure gracefully" do
      issue = build_issue(key: "TEST-FAIL", fields: { "labels" => [ "cw_elements_button" ] })
      allow(client).to receive(:fetch_issue).and_raise(StandardError.new("API error"))

      expect { extractor.save_issues([ issue ]) }.not_to raise_error
    end
  end

  describe "field extraction" do
    it "extracts team from fallback field" do
      issue = build_issue(key: "TEST-TEAM", fields: {
        "customfield_10265" => nil,
        "customfield_10300" => { "value" => "Fallback Team" }
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-TEAM")
      expect(bug.team).to eq("Fallback Team")
    end

    it "handles array team field" do
      issue = build_issue(key: "TEST-ATEAM", fields: {
        "customfield_10265" => [ { "value" => "Team A" }, { "name" => "Team B" } ],
        "customfield_10300" => nil
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-ATEAM")
      expect(bug.team).to eq("Team A,Team B")
    end

    it "handles string team field" do
      issue = build_issue(key: "TEST-STEAM", fields: {
        "customfield_10265" => "Simple Team",
        "customfield_10300" => nil
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-STEAM")
      expect(bug.team).to eq("Simple Team")
    end

    it "extracts RCA from hash field" do
      issue = build_issue(key: "TEST-RCA", fields: {
        "customfield_10249" => { "value" => "Hash RCA" }
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-RCA")
      expect(bug.root_cause_analysis).to eq("Hash RCA")
    end

    it "extracts development_type Frontend" do
      issue = build_issue(key: "TEST-FE", fields: {
        "customfield_10735" => "Frontend"
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-FE")
      expect(bug.development_type).to eq("Frontend")
    end

    it "ignores invalid development_type" do
      issue = build_issue(key: "TEST-INV", fields: {
        "customfield_10735" => "InvalidType"
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-INV")
      expect(bug.development_type).to be_nil
    end

    it "handles nil development_info" do
      issue = build_issue(key: "TEST-NILDEV", fields: {
        "customfield_10735" => nil
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-NILDEV")
      expect(bug.development_type).to be_nil
    end

    it "handles nil comments" do
      issue = build_issue(key: "TEST-NOCOM", fields: {
        "comment" => nil
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-NOCOM")
      expect(bug.comments_count).to eq(0)
    end

    it "handles invalid time values" do
      issue = build_issue(key: "TEST-TIME", fields: {
        "created" => "not-a-date",
        "updated" => nil
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      # Should not raise, but bug may have nil opened_at
      extractor.save_issues([ issue ])
    end

    it "extracts name from displayName field" do
      issue = build_issue(key: "TEST-DN", fields: {
        "reporter" => { "displayName" => "Display Reporter" }
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-DN")
      expect(bug.reporter).to eq("Display Reporter")
    end

    it "extracts name from emailAddress field" do
      issue = build_issue(key: "TEST-EMAIL", fields: {
        "reporter" => { "emailAddress" => "reporter@example.com" }
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-EMAIL")
      expect(bug.reporter).to eq("reporter@example.com")
    end

    it "handles string field values for extract_name" do
      issue = build_issue(key: "TEST-STR", fields: {
        "status" => "Done"
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-STR")
      expect(bug.status).to eq("Done")
    end

    it "extracts RCA from fallback fields" do
      issue = build_issue(key: "TEST-RCAFB", fields: {
        "customfield_10249" => nil,
        "Root Cause" => "Fallback RCA"
      })
      allow(client).to receive(:fetch_issue).and_return(nil)

      extractor.save_issues([ issue ])

      bug = JiraBug.find_by(issue_key: "TEST-RCAFB")
      expect(bug.root_cause_analysis).to eq("Fallback RCA")
    end
  end
end
