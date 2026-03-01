# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning::CycleCapacities", type: :request do
  let(:cycle) { create(:cycle) }

  describe "POST /planning/cycles/:cycle_id/cycle_capacities" do
    let(:developer) { create(:developer) }

    let(:valid_params) do
      {
        developer_cycle_capacity: {
          developer_id: developer.id,
          gross_hours: 80
        }
      }
    end

    it "creates a developer cycle capacity with computed real_capacity" do
      expect {
        post planning_cycle_cycle_capacities_path(cycle), params: valid_params
      }.to change(DeveloperCycleCapacity, :count).by(1)

      capacity = DeveloperCycleCapacity.last
      expected = (80 * developer.productivity_factor).round(2)
      expect(capacity.real_capacity.to_f).to eq(expected)
      expect(response).to redirect_to(plan_planning_cycle_path(cycle))
    end

    it "redirects with alert on invalid params" do
      post planning_cycle_cycle_capacities_path(cycle), params: {
        developer_cycle_capacity: { developer_id: developer.id, gross_hours: "" }
      }

      expect(response).to redirect_to(plan_planning_cycle_path(cycle))
      expect(flash[:alert]).to be_present
    end
  end

  describe "DELETE /planning/cycles/:cycle_id/cycle_capacities/:id" do
    it "removes the developer from the cycle" do
      capacity = create(:developer_cycle_capacity, cycle: cycle)

      expect {
        delete planning_cycle_cycle_capacity_path(cycle, capacity)
      }.to change(DeveloperCycleCapacity, :count).by(-1)

      expect(response).to redirect_to(plan_planning_cycle_path(cycle))
    end
  end

  describe "POST /planning/cycles/:cycle_id/cycle_capacities/add_all" do
    it "adds all available developers with default gross and computed real capacity" do
      dev1 = create(:developer, productivity_factor: 0.8)
      dev2 = create(:developer, productivity_factor: 0.6)

      expect {
        post add_all_planning_cycle_cycle_capacities_path(cycle)
      }.to change(DeveloperCycleCapacity, :count).by(2)

      cap1 = DeveloperCycleCapacity.find_by(developer: dev1)
      cap2 = DeveloperCycleCapacity.find_by(developer: dev2)
      gross = cycle.gross_hours

      expect(cap1.gross_hours.to_f).to eq(gross)
      expect(cap1.real_capacity.to_f).to eq((gross * 0.8).round(2))
      expect(cap2.real_capacity.to_f).to eq((gross * 0.6).round(2))
      expect(response).to redirect_to(plan_planning_cycle_path(cycle))
    end

    it "skips developers already in the cycle" do
      existing = create(:developer)
      create(:developer_cycle_capacity, cycle: cycle, developer: existing)
      new_dev = create(:developer)

      expect {
        post add_all_planning_cycle_cycle_capacities_path(cycle)
      }.to change(DeveloperCycleCapacity, :count).by(1)

      expect(DeveloperCycleCapacity.find_by(developer: new_dev)).to be_present
    end
  end
end
