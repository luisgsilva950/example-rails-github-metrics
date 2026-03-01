# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning::Cycles", type: :request do
  describe "GET /planning/cycles" do
    it "returns a successful response" do
      get planning_cycles_path
      expect(response).to have_http_status(:ok)
    end

    it "displays existing cycles" do
      create(:cycle, name: "Sprint 42")
      get planning_cycles_path
      expect(response.body).to include("Sprint 42")
    end
  end

  describe "GET /planning/cycles/new" do
    it "returns a successful response" do
      get new_planning_cycle_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /planning/cycles" do
    let(:valid_params) do
      { cycle: { name: "Sprint 1", start_date: "2026-03-01", end_date: "2026-03-14" } }
    end

    it "creates a cycle with valid params" do
      expect {
        post planning_cycles_path, params: valid_params
      }.to change(Cycle, :count).by(1)

      expect(response).to redirect_to(planning_cycles_path)
    end

    it "re-renders form with invalid params" do
      post planning_cycles_path, params: { cycle: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /planning/cycles/:id/edit" do
    it "returns a successful response" do
      cycle = create(:cycle)
      get edit_planning_cycle_path(cycle)
      expect(response).to have_http_status(:ok)
    end

    it "displays the cycle form with current values" do
      cycle = create(:cycle, name: "Sprint 99")
      get edit_planning_cycle_path(cycle)
      expect(response.body).to include("Sprint 99")
      expect(response.body).to include("Update Cycle")
    end
  end

  describe "PATCH /planning/cycles/:id" do
    let(:cycle) { create(:cycle, name: "Old Sprint") }

    it "updates the cycle with valid params" do
      patch planning_cycle_path(cycle), params: { cycle: { name: "New Sprint" } }

      expect(response).to redirect_to(planning_cycles_path)
      expect(cycle.reload.name).to eq("New Sprint")
    end

    it "re-renders edit form with invalid params" do
      patch planning_cycle_path(cycle), params: { cycle: { start_date: "2026-03-15", end_date: "2026-03-01" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /planning/cycles/:id/plan" do
    it "returns a successful response" do
      cycle = create(:cycle)
      get plan_planning_cycle_path(cycle)
      expect(response).to have_http_status(:ok)
    end

    it "displays cycle name and planning sections" do
      cycle = create(:cycle, name: "Sprint 50")
      get plan_planning_cycle_path(cycle)
      expect(response.body).to include("Sprint 50")
      expect(response.body).to include("Team")
      expect(response.body).to include("Deliverables")
    end

    it "displays developers assigned to the cycle" do
      cycle = create(:cycle, name: "Sprint 50")
      developer = create(:developer, name: "Jane Planner")
      create(:developer_cycle_capacity, cycle: cycle, developer: developer, gross_hours: 80, real_capacity: 64)

      get plan_planning_cycle_path(cycle)

      expect(response.body).to include("Jane Planner")
      expect(response.body).to include("80.0h")
    end

    it "displays deliverables and their allocations" do
      cycle = create(:cycle)
      deliverable = create(:deliverable, cycle: cycle, title: "Build Dashboard")
      developer = create(:developer, name: "John Dev")
      create(:developer_cycle_capacity, cycle: cycle, developer: developer)
      create(:deliverable_allocation, deliverable: deliverable, developer: developer, allocated_hours: 16)

      get plan_planning_cycle_path(cycle)

      expect(response.body).to include("Build Dashboard")
      expect(response.body).to include("John Dev")
      expect(response.body).to include("16.0h")
    end

    it "displays the Gantt chart with developer allocations and operational activities" do
      cycle = create(:cycle, start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 13))
      create(:cycle_operational_activity, cycle: cycle, name: "bugs",
             start_date: Date.new(2026, 3, 4), end_date: Date.new(2026, 3, 4))
      developer = create(:developer, name: "Alice Gantt")
      create(:developer_cycle_capacity, cycle: cycle, developer: developer, gross_hours: 80, real_capacity: 64)
      deliverable = create(:deliverable, cycle: cycle, title: "Gantt Feature")
      create(:deliverable_allocation,
             deliverable: deliverable,
             developer: developer,
             start_date: Date.new(2026, 3, 2),
             end_date: Date.new(2026, 3, 6))

      get plan_planning_cycle_path(cycle)

      expect(response.body).to include("gantt")
      expect(response.body).to include("Alice Gantt")
      expect(response.body).to include("Operations")
      expect(response.body).to include("gantt__cell--operational")
      expect(response.body).to include("Bugs")
      expect(response.body).to include("Gantt Feature")
      expect(response.body).to include("gantt")
    end
  end
end
