# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning::Developers", type: :request do
  describe "GET /planning/developers" do
    it "returns a successful response" do
      get planning_developers_path
      expect(response).to have_http_status(:ok)
    end

    it "displays existing developers" do
      create(:developer, name: "Jane Doe")
      get planning_developers_path
      expect(response.body).to include("Jane Doe")
    end

    it "filters by stack" do
      create(:developer, name: "Backend Dev", domain_stack: "backend")
      create(:developer, name: "Frontend Dev", domain_stack: "frontend")
      get planning_developers_path, params: { stack: "backend" }
      expect(response.body).to include("Backend Dev")
      expect(response.body).not_to include("Frontend Dev")
    end
  end

  describe "GET /planning/developers/new" do
    it "returns a successful response" do
      get new_planning_developer_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /planning/developers/:id" do
    it "returns a successful response" do
      developer = create(:developer)
      get planning_developer_path(developer)
      expect(response).to have_http_status(:ok)
    end

    it "displays allocations for the developer" do
      developer = create(:developer, name: "Jane Doe")
      deliverable = create(:deliverable, title: "Build API")
      # Mon Feb 23 to Tue Feb 24 = 2 work days = 16h
      create(:deliverable_allocation, developer: developer, deliverable: deliverable,
             start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 2, 24))

      get planning_developer_path(developer)

      expect(response.body).to include("Jane Doe")
      expect(response.body).to include("Build API")
      expect(response.body).to include("16.0h")
    end

    it "displays cycle capacities" do
      developer = create(:developer)
      cycle = create(:cycle, name: "Sprint 10")
      create(:developer_cycle_capacity, developer: developer, cycle: cycle, gross_hours: 40, real_capacity: 32)

      get planning_developer_path(developer)

      expect(response.body).to include("Sprint 10")
      expect(response.body).to include("40.0h")
      expect(response.body).to include("32.0h")
    end
  end

  describe "POST /planning/developers" do
    let(:team) { create(:team) }

    let(:valid_params) do
      {
        developer: {
          team_id: team.id,
          name: "John Smith",
          domain_stack: "backend",
          seniority: "senior",
          productivity_factor: 0.85
        }
      }
    end

    it "creates a developer with valid params" do
      expect {
        post planning_developers_path, params: valid_params
      }.to change(Developer, :count).by(1)

      expect(response).to redirect_to(planning_developers_path)
    end

    it "re-renders form with invalid params" do
      post planning_developers_path, params: { developer: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /planning/developers/:id/edit" do
    it "returns a successful response" do
      developer = create(:developer)
      get edit_planning_developer_path(developer)
      expect(response).to have_http_status(:ok)
    end

    it "displays the developer form with current values" do
      developer = create(:developer, name: "Jane Doe")
      get edit_planning_developer_path(developer)
      expect(response.body).to include("Jane Doe")
      expect(response.body).to include("Update Developer")
    end
  end

  describe "PATCH /planning/developers/:id" do
    let(:developer) { create(:developer, name: "Old Name") }

    it "updates the developer with valid params" do
      patch planning_developer_path(developer), params: { developer: { name: "New Name" } }

      expect(response).to redirect_to(planning_developer_path(developer))
      expect(developer.reload.name).to eq("New Name")
    end

    it "re-renders edit form with invalid params" do
      patch planning_developer_path(developer), params: { developer: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
