# frozen_string_literal: true

require "rails_helper"

RSpec.describe Absence do
  describe "validations" do
    it "is valid with valid attributes" do
      absence = build(:absence)
      expect(absence).to be_valid
    end

    it "requires start_date" do
      absence = build(:absence, start_date: nil)
      expect(absence).not_to be_valid
    end

    it "requires end_date" do
      absence = build(:absence, end_date: nil)
      expect(absence).not_to be_valid
    end

    it "requires end_date on or after start_date" do
      absence = build(:absence, start_date: Date.new(2026, 3, 10), end_date: Date.new(2026, 3, 5))
      expect(absence).not_to be_valid
      expect(absence.errors[:end_date]).to include("must be on or after start date")
    end

    it "allows end_date equal to start_date" do
      absence = build(:absence, start_date: Date.new(2026, 3, 10), end_date: Date.new(2026, 3, 10))
      expect(absence).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a developer" do
      absence = build(:absence)
      expect(absence.developer).to be_present
    end
  end

  describe ".overlapping" do
    let(:developer) { create(:developer) }

    it "returns absences that overlap the given range" do
      overlapping = create(:absence, developer: developer, start_date: Date.new(2026, 3, 9), end_date: Date.new(2026, 3, 13))
      create(:absence, developer: developer, start_date: Date.new(2026, 3, 16), end_date: Date.new(2026, 3, 20))

      result = Absence.overlapping(Date.new(2026, 3, 10), Date.new(2026, 3, 14))
      expect(result).to contain_exactly(overlapping)
    end

    it "returns absences fully contained in the range" do
      contained = create(:absence, developer: developer, start_date: Date.new(2026, 3, 11), end_date: Date.new(2026, 3, 12))

      result = Absence.overlapping(Date.new(2026, 3, 10), Date.new(2026, 3, 14))
      expect(result).to contain_exactly(contained)
    end
  end

  describe "#work_days" do
    it "counts weekdays only" do
      # Mon 2026-03-09 to Fri 2026-03-13 = 5 work days
      absence = build(:absence, start_date: Date.new(2026, 3, 9), end_date: Date.new(2026, 3, 13))
      expect(absence.work_days).to eq(5)
    end

    it "excludes weekends" do
      # Fri 2026-03-06 to Mon 2026-03-09 = 2 work days (Fri + Mon)
      absence = build(:absence, start_date: Date.new(2026, 3, 6), end_date: Date.new(2026, 3, 9))
      expect(absence.work_days).to eq(2)
    end

    it "returns 0 when dates are blank" do
      absence = build(:absence, start_date: nil, end_date: nil)
      expect(absence.work_days).to eq(0)
    end

    it "returns 1 for a single weekday" do
      absence = build(:absence, start_date: Date.new(2026, 3, 10), end_date: Date.new(2026, 3, 10))
      expect(absence.work_days).to eq(1)
    end
  end

  describe "#hours" do
    it "returns work_days times 8" do
      absence = build(:absence, start_date: Date.new(2026, 3, 9), end_date: Date.new(2026, 3, 13))
      expect(absence.hours).to eq(40)
    end
  end
end
