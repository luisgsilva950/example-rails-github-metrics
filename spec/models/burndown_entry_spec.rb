# frozen_string_literal: true

require "rails_helper"

RSpec.describe BurndownEntry do
  subject(:entry) { build(:burndown_entry) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires a date" do
      entry.date = nil
      expect(entry).not_to be_valid
    end

    it "requires deliverable or developer" do
      entry.deliverable = nil
      entry.developer = nil
      expect(entry).not_to be_valid
      expect(entry.errors[:base]).to include("must belong to a deliverable or a developer")
    end

    it "is valid with only a deliverable" do
      entry.developer = nil
      expect(entry).to be_valid
    end

    it "is valid with only developer and cycle" do
      developer = create(:developer)
      cycle = create(:cycle)
      dev_entry = build(:burndown_entry, deliverable: nil, developer: developer, cycle: cycle)
      expect(dev_entry).to be_valid
    end

    it "requires hours_burned >= 0" do
      entry.hours_burned = -1
      expect(entry).not_to be_valid
    end

    it "allows zero hours_burned" do
      entry.hours_burned = 0
      expect(entry).to be_valid
    end

    it "enforces unique date per deliverable" do
      existing = create(:burndown_entry)
      entry.deliverable = existing.deliverable
      entry.date = existing.date
      expect(entry).not_to be_valid
    end

    it "allows same date for different deliverables" do
      create(:burndown_entry, date: entry.date)
      expect(entry).to be_valid
    end

    it "enforces unique date per developer and cycle" do
      developer = create(:developer)
      cycle = create(:cycle)
      create(:burndown_entry, deliverable: nil, developer: developer, cycle: cycle, date: Date.current)
      dup = build(:burndown_entry, deliverable: nil, developer: developer, cycle: cycle, date: Date.current)
      expect(dup).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to a deliverable" do
      expect(entry.deliverable).to be_a(Deliverable)
    end

    it "optionally belongs to a developer" do
      developer = create(:developer)
      cycle = create(:cycle)
      dev_entry = create(:burndown_entry, deliverable: nil, developer: developer, cycle: cycle)
      expect(dev_entry.developer).to be_a(Developer)
      expect(dev_entry.cycle).to be_a(Cycle)
    end
  end
end
