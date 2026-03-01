# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncSetting do
  describe "validations" do
    it "requires key" do
      setting = described_class.new(key: nil)
      expect(setting).not_to be_valid
    end

    it "requires unique key" do
      create(:sync_setting, key: "jira_bugs")
      dup = build(:sync_setting, key: "jira_bugs")
      expect(dup).not_to be_valid
    end
  end

  describe ".for" do
    it "creates a new setting if it does not exist" do
      expect { described_class.for("jira_bugs") }.to change(described_class, :count).by(1)
    end

    it "returns existing setting" do
      existing = create(:sync_setting, key: "jira_bugs")
      expect(described_class.for("jira_bugs")).to eq(existing)
    end
  end

  describe ".enabled?" do
    it "returns false when setting does not exist" do
      expect(described_class.enabled?("jira_bugs")).to be false
    end

    it "returns false when disabled" do
      create(:sync_setting, key: "jira_bugs", enabled: false)
      expect(described_class.enabled?("jira_bugs")).to be false
    end

    it "returns true when enabled" do
      create(:sync_setting, key: "jira_bugs", enabled: true)
      expect(described_class.enabled?("jira_bugs")).to be true
    end
  end

  describe "validations" do
    it "validates status inclusion" do
      setting = build(:sync_setting, status: "invalid")
      expect(setting).not_to be_valid
    end
  end

  describe "#mark_syncing!" do
    it "sets status to syncing and clears last_error" do
      setting = create(:sync_setting, :failed)

      setting.mark_syncing!
      setting.reload

      expect(setting.status).to eq("syncing")
      expect(setting.last_error).to be_nil
    end
  end

  describe "#mark_completed!" do
    it "sets status to completed and updates last_synced_at" do
      setting = create(:sync_setting, status: "syncing")

      setting.mark_completed!
      setting.reload

      expect(setting.status).to eq("completed")
      expect(setting.last_synced_at).to be_within(2.seconds).of(Time.current)
      expect(setting.last_error).to be_nil
    end
  end

  describe "#mark_failed!" do
    it "sets status to failed with error message" do
      setting = create(:sync_setting, status: "syncing")

      setting.mark_failed!("Connection refused")
      setting.reload

      expect(setting.status).to eq("failed")
      expect(setting.last_error).to eq("Connection refused")
    end

    it "truncates long error messages" do
      setting = create(:sync_setting)
      long_message = "x" * 600

      setting.mark_failed!(long_message)

      expect(setting.reload.last_error.length).to be <= 500
    end
  end

  describe "#syncing? / #failed?" do
    it "returns true when status matches" do
      setting = build(:sync_setting, status: "syncing")
      expect(setting).to be_syncing
      expect(setting).not_to be_failed
    end

    it "returns true for failed status" do
      setting = build(:sync_setting, status: "failed")
      expect(setting).to be_failed
      expect(setting).not_to be_syncing
    end
  end
end
