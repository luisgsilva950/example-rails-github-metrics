# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cycle do
  subject(:cycle) { build(:cycle) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires a name" do
      cycle.name = nil
      expect(cycle).not_to be_valid
    end

    it "requires start_date" do
      cycle.start_date = nil
      expect(cycle).not_to be_valid
    end

    it "requires end_date" do
      cycle.end_date = nil
      expect(cycle).not_to be_valid
    end

    it "requires end_date after start_date" do
      cycle.end_date = cycle.start_date - 1.day
      expect(cycle).not_to be_valid
      expect(cycle.errors[:end_date]).to include("must be after start date")
    end
  end

  describe "scopes" do
    it ".current returns active cycles" do
      active = create(:cycle, start_date: 1.day.ago, end_date: 1.day.from_now)
      create(:cycle, start_date: 30.days.ago, end_date: 15.days.ago)
      expect(described_class.current).to eq([ active ])
    end
  end

  describe "#work_days" do
    it "counts only weekdays (Mon-Fri)" do
      # Mon Feb 23 to Fri Feb 27, 2026 = 5 work days
      cycle = build(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      expect(cycle.work_days).to eq(5)
    end

    it "excludes weekends" do
      # Mon Feb 23 to Sun Mar 1, 2026 = 5 weekdays + Sat+Sun = 7 calendar days
      cycle = build(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 1))
      expect(cycle.work_days).to eq(5)
    end
  end

  describe "#gross_hours" do
    it "returns work_days multiplied by 8" do
      # Mon Feb 23 to Fri Feb 27, 2026 = 5 work days = 40 hours
      cycle = build(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      expect(cycle.gross_hours).to eq(40)
    end

    it "excludes holidays from gross hours" do
      create(:holiday, date: Date.new(2026, 2, 24))
      cycle = build(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      expect(cycle.gross_hours).to eq(32)
    end
  end

  describe "#total_weekdays" do
    it "counts weekdays without excluding holidays" do
      create(:holiday, date: Date.new(2026, 2, 24))
      cycle = build(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      expect(cycle.total_weekdays).to eq(5)
    end
  end

  describe "#holiday_count" do
    it "returns the number of holidays within the cycle" do
      create(:holiday, date: Date.new(2026, 2, 24))
      create(:holiday, date: Date.new(2026, 2, 25))
      cycle = build(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      expect(cycle.holiday_count).to eq(2)
    end

    it "returns zero when no holidays exist" do
      cycle = build(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      expect(cycle.holiday_count).to eq(0)
    end
  end

  describe "#operational_days_for" do
    it "counts days covered by team-wide operational activities" do
      # Mon Feb 23 to Fri Feb 27, 2026 = 5 work days
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      developer = create(:developer)
      create(:developer_cycle_capacity, cycle: cycle, developer: developer)
      # Activity covers Wed only
      create(:cycle_operational_activity, cycle: cycle, developer: nil,
             name: "bugs", start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))
      expect(cycle.operational_days_for(developer.id)).to eq(1)
    end

    it "counts days from developer-specific activities" do
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      developer = create(:developer)
      create(:cycle_operational_activity, cycle: cycle, developer: developer,
             name: "bugs", start_date: Date.new(2026, 2, 24), end_date: Date.new(2026, 2, 26))
      # Tue-Thu = 3 days
      expect(cycle.operational_days_for(developer.id)).to eq(3)
    end

    it "does not count activities assigned to other developers" do
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      dev_a = create(:developer)
      dev_b = create(:developer, name: "Other Dev")
      create(:cycle_operational_activity, cycle: cycle, developer: dev_b,
             name: "bugs", start_date: Date.new(2026, 2, 24), end_date: Date.new(2026, 2, 26))
      expect(cycle.operational_days_for(dev_a.id)).to eq(0)
    end

    it "returns zero when no operational activities configured" do
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      developer = create(:developer)
      expect(cycle.operational_days_for(developer.id)).to eq(0)
    end
  end

  describe "#operational_hours_for" do
    it "returns operational_days_for multiplied by 8" do
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      developer = create(:developer)
      create(:cycle_operational_activity, cycle: cycle, developer: nil,
             name: "bugs", start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))
      expect(cycle.operational_hours_for(developer.id)).to eq(8)
    end
  end

  describe "#unallocated_operational_days_for" do
    # Cycle: Mon Feb 23 – Fri Mar 6, 2026 (10 work days)
    # Ops: Mon-Wed each week = 6 ops days total
    let(:cycle) { create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 6)) }
    let(:developer) { create(:developer) }

    before do
      create(:cycle_operational_activity, cycle: cycle, developer: nil,
             name: "bugs", start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 25))
      create(:cycle_operational_activity, cycle: cycle, developer: nil,
             name: "bugs", start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 4))
    end

    it "returns all ops days when no allocations or absences exist" do
      expect(cycle.unallocated_operational_days_for(developer.id)).to eq(6)
    end

    it "excludes ops days covered by an allocation" do
      deliverable = create(:deliverable, cycle: cycle)
      # Alloc covers first week Mon-Fri (5 work days, 3 ops, 2 plannable = 16h)
      create(:deliverable_allocation, deliverable: deliverable, developer: developer,
             start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      # Only second week ops (3 days) remain unallocated
      expect(cycle.unallocated_operational_days_for(developer.id)).to eq(3)
    end

    it "excludes ops days covered by an absence" do
      create(:absence, developer: developer,
             start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 4))
      # Absence covers second week Mon-Wed (3 ops days), first week ops (3) remain
      expect(cycle.unallocated_operational_days_for(developer.id)).to eq(3)
    end

    it "excludes ops days covered by both allocations and absences" do
      deliverable = create(:deliverable, cycle: cycle)
      # Alloc covers first week (3 ops days inside alloc)
      create(:deliverable_allocation, deliverable: deliverable, developer: developer,
             start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      # Absence covers second week Mon-Wed (3 ops days during absence)
      create(:absence, developer: developer,
             start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 4))
      expect(cycle.unallocated_operational_days_for(developer.id)).to eq(0)
    end

    it "returns zero when no operational activities exist" do
      CycleOperationalActivity.delete_all
      expect(cycle.unallocated_operational_days_for(developer.id)).to eq(0)
    end

    it "excludes holidays" do
      create(:holiday, date: Date.new(2026, 2, 24)) # Tue in first week ops range
      # 6 ops days minus 1 holiday = 5 unallocated ops
      expect(cycle.unallocated_operational_days_for(developer.id)).to eq(5)
    end
  end

  describe "#unallocated_operational_hours_for" do
    it "returns unallocated_operational_days_for multiplied by 8" do
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      developer = create(:developer)
      create(:cycle_operational_activity, cycle: cycle, developer: nil,
             name: "bugs", start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))
      # 1 ops day, no allocs/absences → 1 unallocated ops day = 8h
      expect(cycle.unallocated_operational_hours_for(developer.id)).to eq(8)
    end
  end

  describe "holiday exclusion" do
    it "excludes holidays from work_days" do
      create(:holiday, date: Date.new(2026, 2, 24))
      cycle = build(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      expect(cycle.work_days).to eq(4)
    end

    it "excludes holidays from operational_days_for when holiday falls on operational day" do
      create(:holiday, date: Date.new(2026, 2, 25)) # Wednesday
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      developer = create(:developer)
      create(:cycle_operational_activity, cycle: cycle, developer: nil,
             name: "bugs", start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))
      expect(cycle.operational_days_for(developer.id)).to eq(0)
    end
  end
end
