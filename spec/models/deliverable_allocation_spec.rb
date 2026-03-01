# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeliverableAllocation do
  subject(:allocation) { build(:deliverable_allocation) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires start_date" do
      allocation.start_date = nil
      expect(allocation).not_to be_valid
    end

    it "requires end_date" do
      allocation.end_date = nil
      expect(allocation).not_to be_valid
    end

    it "requires end_date on or after start_date" do
      allocation.end_date = allocation.start_date - 1.day
      expect(allocation).not_to be_valid
      expect(allocation.errors[:end_date]).to include("must be after start date")
    end

    it "allows multiple allocations for same developer and deliverable with non-overlapping dates" do
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 20))
      deliverable = create(:deliverable, cycle: cycle)
      developer = create(:developer)
      create(:deliverable_allocation,
             developer: developer, deliverable: deliverable,
             start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

      second = build(:deliverable_allocation,
                     developer: developer, deliverable: deliverable,
                     start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 6))
      expect(second).to be_valid
    end

    describe "no overlapping allocations" do
      let(:cycle) { create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 20)) }
      let(:developer) { create(:developer) }
      let(:deliverable_a) { create(:deliverable, cycle: cycle) }
      let(:deliverable_b) { create(:deliverable, cycle: cycle) }

      it "rejects allocation overlapping existing one for same developer in same cycle" do
        create(:deliverable_allocation,
               developer: developer, deliverable: deliverable_a,
               start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

        overlapping = build(:deliverable_allocation,
                            developer: developer, deliverable: deliverable_b,
                            start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 3, 3))

        expect(overlapping).not_to be_valid
        expect(overlapping.errors[:base].first).to include("already allocated")
      end

      it "allows non-overlapping allocation for same developer in same cycle" do
        create(:deliverable_allocation,
               developer: developer, deliverable: deliverable_a,
               start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

        non_overlapping = build(:deliverable_allocation,
                                developer: developer, deliverable: deliverable_b,
                                start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 6))

        expect(non_overlapping).to be_valid
      end

      it "allows overlapping dates for different developers" do
        other_developer = create(:developer)

        create(:deliverable_allocation,
               developer: developer, deliverable: deliverable_a,
               start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

        other_alloc = build(:deliverable_allocation,
                            developer: other_developer, deliverable: deliverable_b,
                            start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

        expect(other_alloc).to be_valid
      end
    end
  end

  describe "#work_days" do
    it "counts only weekdays" do
      # Mon Feb 23 to Fri Feb 27, 2026 = 5 work days
      allocation = build(:deliverable_allocation, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      expect(allocation.work_days).to eq(5)
    end
  end

  describe "#plannable_days" do
    it "equals work_days when no operational activities configured" do
      # Mon Feb 23 to Fri Feb 27, 2026 = 5 work days, no operational = 5 plannable
      allocation = build(:deliverable_allocation, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      expect(allocation.plannable_days).to eq(5)
    end

    it "excludes operational activity days from plannable days" do
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 6))
      deliverable = create(:deliverable, cycle: cycle)
      developer = create(:developer)
      # Team-wide operational activity on Wed Feb 25
      create(:cycle_operational_activity, cycle: cycle, name: "bugs",
             start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))
      allocation = build(:deliverable_allocation, deliverable: deliverable, developer: developer,
                         start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      # 5 work days - 1 operational day (Wed) = 4 plannable days
      expect(allocation.plannable_days).to eq(4)
    end
  end

  describe "computed allocated_hours" do
    it "sets allocated_hours from plannable_days * 8 before validation" do
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 6))
      deliverable = create(:deliverable, cycle: cycle)
      developer = create(:developer)
      create(:cycle_operational_activity, cycle: cycle, name: "bugs",
             start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))
      allocation = build(:deliverable_allocation, deliverable: deliverable, developer: developer,
                         start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      allocation.valid?
      # 5 work days - 1 operational day = 4 plannable = 32 hours
      expect(allocation.allocated_hours).to eq(32)
    end

    it "uses all work_days when no operational activities" do
      allocation = build(:deliverable_allocation, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      allocation.valid?
      # 5 work days × 8 = 40 hours
      expect(allocation.allocated_hours).to eq(40)
    end
  end

  describe "computed operational_hours" do
    it "sets operational_hours from operational_days * 8" do
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 6))
      deliverable = create(:deliverable, cycle: cycle)
      developer = create(:developer)
      create(:cycle_operational_activity, cycle: cycle, name: "bugs",
             start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))
      allocation = build(:deliverable_allocation, deliverable: deliverable, developer: developer,
                         start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      allocation.valid?
      # 1 operational day (Wed 25) = 8 operational hours
      expect(allocation.operational_hours).to eq(8)
    end

    it "computes zero operational_hours when no activities configured" do
      allocation = build(:deliverable_allocation, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 24))
      allocation.valid?
      expect(allocation.operational_hours).to eq(0)
    end
  end

  describe "holiday exclusion" do
    it "excludes holidays from work_days" do
      create(:holiday, date: Date.new(2026, 2, 24))
      allocation = build(:deliverable_allocation, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      expect(allocation.work_days).to eq(4)
    end

    it "excludes holiday operational days from operational_days" do
      create(:holiday, date: Date.new(2026, 2, 25)) # Wednesday
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 6))
      deliverable = create(:deliverable, cycle: cycle)
      developer = create(:developer)
      create(:cycle_operational_activity, cycle: cycle, name: "bugs",
             start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))
      allocation = build(:deliverable_allocation, deliverable: deliverable, developer: developer,
                         start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      expect(allocation.operational_days).to eq(0)
    end

    it "adjusts allocated_hours when holiday present" do
      create(:holiday, date: Date.new(2026, 2, 24))
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 6))
      deliverable = create(:deliverable, cycle: cycle)
      developer = create(:developer)
      create(:cycle_operational_activity, cycle: cycle, name: "bugs",
             start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))
      allocation = build(:deliverable_allocation, deliverable: deliverable, developer: developer,
                         start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      allocation.valid?
      # 5 work days - 1 holiday = 4 work days - 1 operational (Wed) = 3 plannable = 24h
      expect(allocation.allocated_hours).to eq(24)
    end
  end

  describe "auto-split on create" do
    it "splits the allocation when a holiday falls inside the range" do
      create(:holiday, date: Date.new(2026, 2, 25))
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 6))
      deliverable = create(:deliverable, cycle: cycle)
      developer = create(:developer)

      DeliverableAllocation.create!(
        deliverable: deliverable, developer: developer,
        start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27),
        allocated_hours: 1, operational_hours: 0
      )

      splits = DeliverableAllocation.where(deliverable: deliverable, developer: developer).order(:start_date)
      expect(splits.size).to eq(2)
      expect(splits.first.end_date).to eq(Date.new(2026, 2, 24))
      expect(splits.last.start_date).to eq(Date.new(2026, 2, 26))
    end

    it "splits the allocation when an absence falls inside the range" do
      cycle = create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 6))
      deliverable = create(:deliverable, cycle: cycle)
      developer = create(:developer)
      create(:absence, developer: developer,
             start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))

      DeliverableAllocation.create!(
        deliverable: deliverable, developer: developer,
        start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27),
        allocated_hours: 1, operational_hours: 0
      )

      splits = DeliverableAllocation.where(deliverable: deliverable, developer: developer).order(:start_date)
      expect(splits.size).to eq(2)
      expect(splits.first.end_date).to eq(Date.new(2026, 2, 24))
      expect(splits.last.start_date).to eq(Date.new(2026, 2, 26))
    end

    it "does not split when skip_auto_split is true" do
      create(:holiday, date: Date.new(2026, 2, 25))
      alloc = create(:deliverable_allocation,
                     start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

      expect(alloc).to be_persisted
      expect(DeliverableAllocation.count).to eq(1)
    end
  end
end
