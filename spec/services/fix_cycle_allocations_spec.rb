# frozen_string_literal: true

require "rails_helper"

RSpec.describe FixCycleAllocations do
  subject(:service) { described_class.new }

  let(:cycle) { create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 20)) }
  let(:deliverable) { create(:deliverable, cycle: cycle) }

  it "splits allocations with holidays for all developers in the cycle" do
    create(:holiday, date: Date.new(2026, 2, 25))
    dev1 = create(:developer)
    dev2 = create(:developer)
    DeliverableAllocation.create_without_auto_split!(
      deliverable: deliverable, developer: dev1,
      start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27),
      allocated_hours: 1, operational_hours: 0
    )
    DeliverableAllocation.create_without_auto_split!(
      deliverable: deliverable, developer: dev2,
      start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27),
      allocated_hours: 1, operational_hours: 0
    )

    expect { service.call(cycle: cycle) }.to change(DeliverableAllocation, :count).by(2)
  end

  it "splits allocations with absences for the correct developer" do
    dev = create(:developer)
    create(:absence, developer: dev,
           start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))
    DeliverableAllocation.create_without_auto_split!(
      deliverable: deliverable, developer: dev,
      start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27),
      allocated_hours: 1, operational_hours: 0
    )

    service.call(cycle: cycle)

    splits = DeliverableAllocation.where(developer: dev).order(:start_date)
    expect(splits.size).to eq(2)
    expect(splits.first.end_date).to eq(Date.new(2026, 2, 24))
    expect(splits.last.start_date).to eq(Date.new(2026, 2, 26))
  end

  it "does nothing when allocations are clean" do
    dev = create(:developer)
    DeliverableAllocation.create_without_auto_split!(
      deliverable: deliverable, developer: dev,
      start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 27),
      allocated_hours: 1, operational_hours: 0
    )

    expect { service.call(cycle: cycle) }.not_to change(DeliverableAllocation, :count)
  end
end
