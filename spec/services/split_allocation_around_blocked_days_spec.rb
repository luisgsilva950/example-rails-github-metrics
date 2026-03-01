# frozen_string_literal: true

require "rails_helper"

RSpec.describe SplitAllocationAroundBlockedDays do
  subject(:service) { described_class.new }

  let(:cycle) { create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 20)) }
  let(:deliverable) { create(:deliverable, cycle: cycle) }
  let(:developer) { create(:developer) }

  def create_alloc(start_date:, end_date:)
    DeliverableAllocation.create_without_auto_split!(
      deliverable: deliverable, developer: developer,
      start_date: start_date, end_date: end_date,
      allocated_hours: 1, operational_hours: 0
    )
  end

  def splits
    DeliverableAllocation.where(deliverable: deliverable, developer: developer).order(:start_date)
  end

  context "with holidays" do
    it "does nothing when no blocked days exist" do
      alloc = create_alloc(start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))
      expect { service.call(allocation: alloc) }.not_to change(DeliverableAllocation, :count)
    end

    it "splits around a single holiday" do
      create(:holiday, date: Date.new(2026, 2, 25))
      alloc = create_alloc(start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

      service.call(allocation: alloc)

      expect(splits.size).to eq(2)
      expect(splits.first.start_date).to eq(Date.new(2026, 2, 23))
      expect(splits.first.end_date).to eq(Date.new(2026, 2, 24))
      expect(splits.last.start_date).to eq(Date.new(2026, 2, 26))
      expect(splits.last.end_date).to eq(Date.new(2026, 2, 27))
    end

    it "splits around consecutive holidays" do
      create(:holiday, date: Date.new(2026, 2, 25))
      create(:holiday, date: Date.new(2026, 2, 26))
      alloc = create_alloc(start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

      service.call(allocation: alloc)

      expect(splits.size).to eq(2)
      expect(splits.first.end_date).to eq(Date.new(2026, 2, 24))
      expect(splits.last.start_date).to eq(Date.new(2026, 2, 27))
    end

    it "discards segments with no work days" do
      create(:holiday, date: Date.new(2026, 2, 23))
      alloc = create_alloc(start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

      service.call(allocation: alloc)

      expect(splits.size).to eq(1)
      expect(splits.first.start_date).to eq(Date.new(2026, 2, 24))
    end

    it "ignores weekend holidays" do
      create(:holiday, date: Date.new(2026, 2, 28)) # Saturday
      alloc = create_alloc(start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 1))

      expect { service.call(allocation: alloc) }.not_to change(DeliverableAllocation, :count)
    end

    it "computes allocated_hours correctly on split segments" do
      create(:holiday, date: Date.new(2026, 2, 25))
      alloc = create_alloc(start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

      service.call(allocation: alloc)

      expect(splits.first.allocated_hours).to eq(16) # Mon-Tue
      expect(splits.last.allocated_hours).to eq(16)  # Thu-Fri
    end
  end

  context "with absences" do
    it "splits around a developer absence" do
      create(:absence, developer: developer,
             start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 26))
      alloc = create_alloc(start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

      service.call(allocation: alloc)

      expect(splits.size).to eq(2)
      expect(splits.first.end_date).to eq(Date.new(2026, 2, 24))
      expect(splits.last.start_date).to eq(Date.new(2026, 2, 27))
    end

    it "does not split for another developer's absence" do
      other = create(:developer)
      create(:absence, developer: other,
             start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))
      alloc = create_alloc(start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

      expect { service.call(allocation: alloc) }.not_to change(DeliverableAllocation, :count)
    end
  end

  context "with holidays and absences combined" do
    it "splits around both holidays and absences" do
      create(:holiday, date: Date.new(2026, 2, 24))        # Tue
      create(:absence, developer: developer,
             start_date: Date.new(2026, 2, 26), end_date: Date.new(2026, 2, 26))  # Thu
      alloc = create_alloc(start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27))

      service.call(allocation: alloc)

      # Blocked: Tue 24 + Thu 26 → segments: Mon 23, Wed 25, Fri 27
      expect(splits.size).to eq(3)
      expect(splits[0].start_date).to eq(Date.new(2026, 2, 23))
      expect(splits[0].end_date).to eq(Date.new(2026, 2, 23))
      expect(splits[1].start_date).to eq(Date.new(2026, 2, 25))
      expect(splits[1].end_date).to eq(Date.new(2026, 2, 25))
      expect(splits[2].start_date).to eq(Date.new(2026, 2, 27))
      expect(splits[2].end_date).to eq(Date.new(2026, 2, 27))
    end
  end

  it "is idempotent on already clean allocations" do
    create(:holiday, date: Date.new(2026, 2, 25))
    alloc = create_alloc(start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 24))

    expect { service.call(allocation: alloc) }.not_to change(DeliverableAllocation, :count)
  end
end
