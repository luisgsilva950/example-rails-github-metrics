# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncDatesToJira do
  let(:fake_client) { instance_double(JiraClient) }

  subject(:service) { described_class.new(client: fake_client) }

  let(:team) { create(:team) }
  let(:cycle) { create(:cycle) }
  let(:deliverable) do
    create(:deliverable, team: team, cycle: cycle, jira_link: "https://jira.example.com/browse/PROJ-123")
  end

  describe "#call" do
    context "when deliverable has no jira_link" do
      let(:deliverable) { create(:deliverable, team: team, jira_link: nil) }

      it "returns failure with error message" do
        result = service.call(deliverable: deliverable)

        expect(result).to eq(success: false, error: "No valid Jira issue key found in link")
      end
    end

    context "when jira_link has no valid issue key" do
      let(:deliverable) { create(:deliverable, team: team, jira_link: "https://jira.example.com/invalid") }

      it "returns failure with error message" do
        result = service.call(deliverable: deliverable)

        expect(result).to eq(success: false, error: "No valid Jira issue key found in link")
      end
    end

    context "when deliverable has no allocations" do
      it "returns failure with error message" do
        result = service.call(deliverable: deliverable)

        expect(result).to eq(success: false, error: "No allocations found for this deliverable")
      end
    end

    context "when deliverable has allocations" do
      let(:developer) { create(:developer, team: team) }

      before do
        create(:deliverable_allocation,
               deliverable: deliverable,
               developer: developer,
               start_date: Date.new(2025, 1, 6),
               end_date: Date.new(2025, 1, 10))
      end

      it "syncs dates to Jira and returns success" do
        allow(fake_client).to receive(:update_issue)

        result = service.call(deliverable: deliverable)

        expect(result).to eq(success: true, issue_key: "PROJ-123")
        expect(fake_client).to have_received(:update_issue).with(
          key: "PROJ-123",
          fields: {
            "customfield_10357" => "2025-01-06",
            "customfield_10015" => "2025-01-06",
            "customfield_10487" => "2025-01-10"
          }
        )
      end
    end

    context "with multiple allocations spanning different dates" do
      let(:dev1) { create(:developer, team: team) }
      let(:dev2) { create(:developer, team: team) }

      before do
        create(:deliverable_allocation,
               deliverable: deliverable,
               developer: dev1,
               start_date: Date.new(2025, 1, 6),
               end_date: Date.new(2025, 1, 10))
        create(:deliverable_allocation,
               deliverable: deliverable,
               developer: dev2,
               start_date: Date.new(2025, 1, 13),
               end_date: Date.new(2025, 1, 17))
      end

      it "uses the earliest start and latest end across all allocations" do
        allow(fake_client).to receive(:update_issue)

        result = service.call(deliverable: deliverable)

        expect(result).to eq(success: true, issue_key: "PROJ-123")
        expect(fake_client).to have_received(:update_issue).with(
          key: "PROJ-123",
          fields: {
            "customfield_10357" => "2025-01-06",
            "customfield_10015" => "2025-01-06",
            "customfield_10487" => "2025-01-17"
          }
        )
      end
    end

    context "with custom JIRA field env vars" do
      let(:developer) { create(:developer, team: team) }

      before do
        create(:deliverable_allocation,
               deliverable: deliverable,
               developer: developer,
               start_date: Date.new(2025, 1, 6),
               end_date: Date.new(2025, 1, 10))
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("JIRA_PLANNED_START_DATE_FIELD", "customfield_10357").and_return("customfield_99999")
        allow(ENV).to receive(:fetch).with("JIRA_PLANNED_END_DATE_FIELD", "customfield_10487").and_return("customfield_88888")
      end

      it "uses the configured field names" do
        allow(fake_client).to receive(:update_issue)

        service.call(deliverable: deliverable)

        expect(fake_client).to have_received(:update_issue).with(
          key: "PROJ-123",
          fields: {
            "customfield_99999" => "2025-01-06",
            "customfield_10015" => "2025-01-06",
            "customfield_88888" => "2025-01-10"
          }
        )
      end
    end
  end
end
