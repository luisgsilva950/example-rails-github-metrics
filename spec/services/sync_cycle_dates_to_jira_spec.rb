# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncCycleDatesToJira do
  let(:fake_sync) { instance_double(SyncDatesToJira) }

  subject(:service) { described_class.new(sync_service: fake_sync) }

  let(:team) { create(:team) }
  let(:cycle) { create(:cycle) }

  describe "#call" do
    context "when cycle has no deliverables with jira links" do
      before { create(:deliverable, team: team, cycle: cycle, jira_link: nil) }

      it "returns empty results" do
        result = service.call(cycle: cycle)

        expect(result).to eq(results: [], total: 0)
      end
    end

    context "when cycle has deliverables with jira links" do
      let!(:d1) { create(:deliverable, team: team, cycle: cycle, jira_link: "https://jira.example.com/browse/PROJ-1") }
      let!(:d2) { create(:deliverable, team: team, cycle: cycle, jira_link: "https://jira.example.com/browse/PROJ-2") }
      let!(:d3) { create(:deliverable, team: team, cycle: cycle, jira_link: nil) }

      it "syncs only deliverables with jira links" do
        allow(fake_sync).to receive(:call)
          .with(deliverable: d1).and_return(success: true, issue_key: "PROJ-1")
        allow(fake_sync).to receive(:call)
          .with(deliverable: d2).and_return(success: true, issue_key: "PROJ-2")

        result = service.call(cycle: cycle)

        expect(result[:total]).to eq(2)
        expect(result[:results]).to contain_exactly(
          hash_including(title: d1.title, success: true, issue_key: "PROJ-1"),
          hash_including(title: d2.title, success: true, issue_key: "PROJ-2")
        )
      end
    end

    context "when one sync fails with an exception" do
      let!(:d1) { create(:deliverable, team: team, cycle: cycle, jira_link: "https://jira.example.com/browse/PROJ-1") }

      it "catches the error and includes it in results" do
        allow(fake_sync).to receive(:call)
          .with(deliverable: d1).and_raise(StandardError.new("timeout"))

        result = service.call(cycle: cycle)

        expect(result[:total]).to eq(1)
        expect(result[:results].first).to include(success: false, error: "timeout")
      end
    end
  end
end
