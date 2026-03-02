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
      expect(response.body).to include("Gross")
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

    it "displays unforeseen badge on cells with burndown entries" do
      cycle = create(:cycle, start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 13))
      developer = create(:developer, name: "Bob Unforeseen Event")
      create(:developer_cycle_capacity, cycle: cycle, developer: developer, gross_hours: 80, real_capacity: 64)
      deliverable = create(:deliverable, cycle: cycle, title: "Feature X")
      create(:deliverable_allocation,
             deliverable: deliverable,
             developer: developer,
             start_date: Date.new(2026, 3, 2),
             end_date: Date.new(2026, 3, 6))
      create(:burndown_entry,
             deliverable: deliverable,
             date: Date.new(2026, 3, 3),
             hours_burned: 0,
             note: "Bug")

      get plan_planning_cycle_path(cycle)

      expect(response.body).to include("gantt__cell--unforeseen")
      expect(response.body).to include("gantt__unforeseen-badge")
    end

    it "renders data-tooltip on deliverable allocation cells" do
      cycle = create(:cycle, start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 6))
      developer = create(:developer, name: "Tooltip Dev")
      create(:developer_cycle_capacity, cycle: cycle, developer: developer)
      deliverable = create(:deliverable, cycle: cycle, title: "Tooltip Feature")
      create(:deliverable_allocation,
             deliverable: deliverable,
             developer: developer,
             start_date: Date.new(2026, 3, 2),
             end_date: Date.new(2026, 3, 4))

      get plan_planning_cycle_path(cycle)

      expect(response.body).to include('data-tooltip="Tooltip Feature')
      expect(response.body).to include("gantt__cell--has-tooltip")
    end

    it "renders click action on deliverable allocation cells for unforeseen" do
      cycle = create(:cycle, start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 6))
      developer = create(:developer, name: "Click Dev")
      create(:developer_cycle_capacity, cycle: cycle, developer: developer)
      deliverable = create(:deliverable, cycle: cycle, title: "Click Feature")
      create(:deliverable_allocation,
             deliverable: deliverable,
             developer: developer,
             start_date: Date.new(2026, 3, 2),
             end_date: Date.new(2026, 3, 4))

      get plan_planning_cycle_path(cycle)

      expect(response.body).to include("click->gantt-click#filledCellClicked")
      expect(response.body).to include("data-deliverable-id=")
    end

    it "renders unforeseen data attributes on cells with burndown entries" do
      cycle = create(:cycle, start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 6))
      developer = create(:developer, name: "Unforeseen Event Dev")
      create(:developer_cycle_capacity, cycle: cycle, developer: developer)
      deliverable = create(:deliverable, cycle: cycle, title: "Unforeseen Event Feature")
      create(:deliverable_allocation,
             deliverable: deliverable,
             developer: developer,
             start_date: Date.new(2026, 3, 2),
             end_date: Date.new(2026, 3, 4))
      entry = create(:burndown_entry,
                     deliverable: deliverable,
                     date: Date.new(2026, 3, 3),
                     hours_burned: 0,
                     note: "Bug fix")

      get plan_planning_cycle_path(cycle)

      expect(response.body).to include("data-unforeseen-id=\"#{entry.id}\"")
      expect(response.body).to include('data-unforeseen-note="Bug fix"')
      expect(response.body).to include('data-unforeseen-hours="0.0"')
    end
  end

  describe "GET /planning/cycles/:id/burndown" do
    let(:monday) { Date.new(2026, 3, 2) }
    let(:friday) { Date.new(2026, 3, 6) }
    let(:cycle) { create(:cycle, start_date: monday, end_date: friday) }

    it "returns JSON with burndown data" do
      deliverable = create(:deliverable, cycle: cycle, title: "Feature X", total_effort_hours: 40)

      get burndown_planning_cycle_path(cycle, format: :json)

      expect(response).to have_http_status(:ok)
      data = response.parsed_body
      expect(data.size).to eq(1)
      expect(data.first["title"]).to eq("Feature X")
      expect(data.first["effort"]).to eq(40.0)
      expect(data.first["ideal"]).to be_an(Array)
      expect(data.first["planned"]).to be_an(Array)
    end

    it "returns empty array when no deliverables" do
      get burndown_planning_cycle_path(cycle, format: :json)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end

    it "includes multiple deliverables" do
      create(:deliverable, cycle: cycle, title: "Feature A")
      create(:deliverable, cycle: cycle, title: "Feature B")

      get burndown_planning_cycle_path(cycle, format: :json)

      titles = response.parsed_body.map { |d| d["title"] }
      expect(titles).to contain_exactly("Feature A", "Feature B")
    end

    it "reflects allocation data in planned line" do
      deliverable = create(:deliverable, cycle: cycle, total_effort_hours: 40)
      developer = create(:developer)
      create(:developer_cycle_capacity, cycle: cycle, developer: developer)
      create(:deliverable_allocation,
             deliverable: deliverable,
             developer: developer,
             start_date: monday,
             end_date: friday)

      get burndown_planning_cycle_path(cycle, format: :json)

      planned = response.parsed_body.first["planned"]
      remaining_values = planned.map { |p| p["remaining"] }
      expect(remaining_values.last).to be < remaining_values.first
    end
  end

  describe "Gantt CSS prevents horizontal blank space" do
    it "has overflow:hidden on filled cells to prevent tooltip scroll bleed" do
      css = Rails.root.join("app/assets/stylesheets/application.css").read

      filled_rule = css[/\.plan-dark\s+\.gantt__cell--filled\s*\{[^}]+\}/m]
      expect(filled_rule).to include("overflow: hidden"), "gantt__cell--filled must have overflow:hidden to prevent blank scroll space"
    end
  end
end
