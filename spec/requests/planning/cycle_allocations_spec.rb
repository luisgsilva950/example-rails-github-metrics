# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning::CycleAllocations", type: :request do
  let(:cycle) { create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 6)) }

  describe "POST /planning/cycles/:cycle_id/cycle_allocations" do
    let(:developer) { create(:developer) }
    let(:deliverable) { create(:deliverable, cycle: cycle, total_effort_hours: 40) }

    let(:valid_params) do
      {
        deliverable_allocation: {
          deliverable_id: deliverable.id,
          developer_id: developer.id,
          start_date: "2026-02-23",
          end_date: "2026-02-27"
        }
      }
    end

    it "creates an allocation with hours computed from plannable days" do
      create(:cycle_operational_activity, cycle: cycle, name: "bugs",
             start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 25))
      post planning_cycle_cycle_allocations_path(cycle), params: valid_params

      expect(DeliverableAllocation.count).to eq(1)
      alloc = DeliverableAllocation.last
      # Mon-Fri = 5 work days - 1 operational day (Wed 25) = 4 plannable days × 8 = 32h
      expect(alloc.allocated_hours.to_f).to eq(32.0)
      expect(alloc.start_date).to eq(Date.new(2026, 2, 23))
      expect(alloc.end_date).to eq(Date.new(2026, 2, 27))
      expect(response).to redirect_to(plan_planning_cycle_path(cycle, anchor: "deliverable-#{deliverable.id}"))
    end

    it "redirects with alert on invalid params" do
      post planning_cycle_cycle_allocations_path(cycle), params: {
        deliverable_allocation: { deliverable_id: deliverable.id, developer_id: "", start_date: "", end_date: "" }
      }

      expect(response).to redirect_to(plan_planning_cycle_path(cycle, anchor: "deliverable-#{deliverable.id}"))
      expect(flash[:alert]).to be_present
    end

    it "rejects allocation that overlaps an existing one for same developer" do
      other_deliverable = create(:deliverable, cycle: cycle)
      create(:deliverable_allocation,
             developer: developer, deliverable: other_deliverable,
             start_date: "2026-02-23", end_date: "2026-02-27")

      post planning_cycle_cycle_allocations_path(cycle), params: {
        deliverable_allocation: {
          deliverable_id: deliverable.id,
          developer_id: developer.id,
          start_date: "2026-02-25",
          end_date: "2026-03-03"
        }
      }

      expect(DeliverableAllocation.count).to eq(1) # only the pre-existing one
      expect(flash[:alert]).to include("already allocated")
    end
  end

  describe "DELETE /planning/cycles/:cycle_id/cycle_allocations/:id" do
    it "removes the allocation" do
      deliverable = create(:deliverable, cycle: cycle)
      allocation = create(:deliverable_allocation, deliverable: deliverable)

      expect {
        delete planning_cycle_cycle_allocation_path(cycle, allocation)
      }.to change(DeliverableAllocation, :count).by(-1)

      expect(response).to redirect_to(plan_planning_cycle_path(cycle, anchor: "deliverable-#{deliverable.id}"))
    end
  end

  describe "PATCH /planning/cycles/:cycle_id/cycle_allocations/:id" do
    it "updates the allocation dates" do
      deliverable = create(:deliverable, cycle: cycle)
      allocation = create(:deliverable_allocation, deliverable: deliverable,
                          start_date: cycle.start_date, end_date: cycle.start_date + 2.days)

      new_end = cycle.start_date + 5.days
      patch planning_cycle_cycle_allocation_path(cycle, allocation),
            params: { deliverable_allocation: { start_date: cycle.start_date, end_date: new_end } }

      expect(response).to redirect_to(plan_planning_cycle_path(cycle, anchor: "deliverable-#{deliverable.id}"))
      expect(allocation.reload.end_date).to eq(new_end)
    end

    it "redirects with alert on invalid dates" do
      deliverable = create(:deliverable, cycle: cycle)
      allocation = create(:deliverable_allocation, deliverable: deliverable,
                          start_date: cycle.start_date, end_date: cycle.start_date + 2.days)

      patch planning_cycle_cycle_allocation_path(cycle, allocation),
            params: { deliverable_allocation: { start_date: cycle.end_date, end_date: cycle.start_date } }

      expect(response).to redirect_to(plan_planning_cycle_path(cycle, anchor: "deliverable-#{deliverable.id}"))
      expect(flash[:alert]).to be_present
    end

    it "rejects update that causes overlap with another allocation" do
      deliverable = create(:deliverable, cycle: cycle)
      developer = create(:developer)
      allocation = create(:deliverable_allocation, developer: developer, deliverable: deliverable,
                          start_date: "2026-02-23", end_date: "2026-02-25")

      other_deliverable = create(:deliverable, cycle: cycle)
      create(:deliverable_allocation, developer: developer, deliverable: other_deliverable,
             start_date: "2026-02-26", end_date: "2026-03-03")

      patch planning_cycle_cycle_allocation_path(cycle, allocation),
            params: { deliverable_allocation: { start_date: "2026-02-23", end_date: "2026-02-27" } }

      expect(flash[:alert]).to include("already allocated")
      expect(allocation.reload.end_date).to eq(Date.new(2026, 2, 25))
    end
  end
end
