# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncJiraBugsJob do
  describe "#perform" do
    it "does nothing when sync is disabled" do
      create(:sync_setting, key: "jira_bugs", enabled: false)

      expect(JiraBugsExtractor).not_to receive(:new)

      described_class.new.perform
    end

    it "calls extractor and marks completed when enabled" do
      setting = create(:sync_setting, key: "jira_bugs", enabled: true, last_synced_at: 1.hour.ago)

      fake_client = instance_double(JiraClient)
      allow(JiraClient).to receive(:new).and_return(fake_client)

      extractor = instance_double(JiraBugsExtractor, call: nil)
      expect(JiraBugsExtractor).to receive(:new)
        .with(hash_including(client: fake_client))
        .and_return(extractor)

      described_class.new.perform

      setting.reload
      expect(setting.status).to eq("completed")
      expect(setting.last_synced_at).to be_within(2.seconds).of(Time.current)
      expect(setting.last_error).to be_nil
    end

    it "marks failed and re-raises when extractor raises" do
      setting = create(:sync_setting, key: "jira_bugs", enabled: true)

      fake_client = instance_double(JiraClient)
      allow(JiraClient).to receive(:new).and_return(fake_client)

      extractor = instance_double(JiraBugsExtractor)
      allow(JiraBugsExtractor).to receive(:new).and_return(extractor)
      allow(extractor).to receive(:call).and_raise(StandardError, "JIRA unreachable")

      expect { described_class.new.perform }.to raise_error(StandardError, "JIRA unreachable")

      setting.reload
      expect(setting.status).to eq("failed")
      expect(setting.last_error).to eq("JIRA unreachable")
    end
  end
end
