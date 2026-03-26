# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncSonarMetrics do
  describe "#call" do
    let(:fake_client) { instance_double(SonarCloudClient) }

    subject(:service) { described_class.new(client: fake_client) }

    it "updates cached metrics on each project" do
      project = create(:sonar_project, sonar_key: "org_repo", bugs: 0, coverage: 0.0)

      allow(fake_client).to receive(:measures).with(component_key: "org_repo").and_return(
        "component" => {
          "key" => "org_repo",
          "measures" => [
            { "metric" => "bugs", "value" => "5" },
            { "metric" => "vulnerabilities", "value" => "2" },
            { "metric" => "code_smells", "value" => "10" },
            { "metric" => "security_hotspots", "value" => "1" },
            { "metric" => "ncloc", "value" => "5000" },
            { "metric" => "coverage", "value" => "75.3" },
            { "metric" => "duplicated_lines_density", "value" => "2.1" },
            { "metric" => "reliability_rating", "value" => "1.0" },
            { "metric" => "security_rating", "value" => "2.0" },
            { "metric" => "sqale_rating", "value" => "3.0" }
          ]
        }
      )

      service.call

      project.reload
      expect(project.bugs).to eq(5)
      expect(project.vulnerabilities).to eq(2)
      expect(project.code_smells).to eq(10)
      expect(project.security_hotspots).to eq(1)
      expect(project.ncloc).to eq(5000)
      expect(project.coverage).to eq(75.3)
      expect(project.duplicated_lines_density).to eq(2.1)
      expect(project.reliability_rating).to eq("A")
      expect(project.security_rating).to eq("B")
      expect(project.sqale_rating).to eq("C")
      expect(project.metrics_synced_at).to be_within(2.seconds).of(Time.current)
    end

    it "handles missing measures gracefully" do
      project = create(:sonar_project, sonar_key: "org_empty")

      allow(fake_client).to receive(:measures).with(component_key: "org_empty").and_return(
        "component" => { "key" => "org_empty", "measures" => [] }
      )

      service.call

      project.reload
      expect(project.bugs).to eq(0)
      expect(project.coverage).to eq(0.0)
    end

    context "when since is provided" do
      let(:measures_response) do
        {
          "component" => {
            "measures" => [
              { "metric" => "bugs", "value" => "3" },
              { "metric" => "vulnerabilities", "value" => "0" },
              { "metric" => "code_smells", "value" => "0" },
              { "metric" => "security_hotspots", "value" => "0" },
              { "metric" => "ncloc", "value" => "100" },
              { "metric" => "coverage", "value" => "50.0" },
              { "metric" => "duplicated_lines_density", "value" => "0" },
              { "metric" => "reliability_rating", "value" => "1.0" },
              { "metric" => "security_rating", "value" => "1.0" },
              { "metric" => "sqale_rating", "value" => "1.0" }
            ]
          }
        }
      end

      it "skips projects already synced after the since timestamp" do
        already_synced = create(:sonar_project, sonar_key: "synced", metrics_synced_at: 1.hour.ago)
        not_synced = create(:sonar_project, sonar_key: "not_synced", metrics_synced_at: nil)

        allow(fake_client).to receive(:measures)
          .with(component_key: "not_synced")
          .and_return(measures_response)

        service.call(since: 2.hours.ago)

        expect(fake_client).not_to have_received(:measures).with(component_key: "synced")
        expect(not_synced.reload.metrics_synced_at).to be_within(2.seconds).of(Time.current)
      end

      it "re-syncs projects with stale metrics" do
        stale = create(:sonar_project, sonar_key: "stale", metrics_synced_at: 10.hours.ago)

        allow(fake_client).to receive(:measures)
          .with(component_key: "stale")
          .and_return(measures_response)

        service.call(since: 6.hours.ago)

        expect(stale.reload.bugs).to eq(3)
      end

      it "syncs all projects when since is nil" do
        project_a = create(:sonar_project, sonar_key: "a", metrics_synced_at: 1.hour.ago)
        project_b = create(:sonar_project, sonar_key: "b", metrics_synced_at: nil)

        allow(fake_client).to receive(:measures).and_return(measures_response)

        service.call(since: nil)

        expect(fake_client).to have_received(:measures).with(component_key: "a")
        expect(fake_client).to have_received(:measures).with(component_key: "b")
      end
    end
  end
end
