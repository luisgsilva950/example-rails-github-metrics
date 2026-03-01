# frozen_string_literal: true

require "rails_helper"

RSpec.describe Deliverable do
  subject(:deliverable) { build(:deliverable) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires a title" do
      deliverable.title = nil
      expect(deliverable).not_to be_valid
    end

    it "requires a valid specific_stack" do
      deliverable.specific_stack = "cobol"
      expect(deliverable).not_to be_valid
    end

    it "requires a valid status" do
      deliverable.status = "cancelled"
      expect(deliverable).not_to be_valid
    end

    it "allows nil cycle (backlog)" do
      deliverable.cycle = nil
      expect(deliverable).to be_valid
    end

    it "defaults deliverable_type to bet" do
      d = Deliverable.new
      expect(d.deliverable_type).to eq("bet")
    end

    it "accepts spillover as deliverable_type" do
      deliverable.deliverable_type = "spillover"
      expect(deliverable).to be_valid
    end

    it "accepts technical_debt as deliverable_type" do
      deliverable.deliverable_type = "technical_debt"
      expect(deliverable).to be_valid
    end

    it "rejects invalid deliverable_type" do
      deliverable.deliverable_type = "epic"
      expect(deliverable).not_to be_valid
    end
  end

  describe "scopes" do
    it ".backlog returns deliverables without a cycle" do
      backlog_item = create(:deliverable, cycle: nil)
      create(:deliverable, cycle: create(:cycle))
      expect(described_class.backlog).to eq([ backlog_item ])
    end

    it ".by_status filters by status" do
      done = create(:deliverable, status: "done")
      create(:deliverable, status: "backlog")
      expect(described_class.by_status("done")).to eq([ done ])
    end
  end
end
