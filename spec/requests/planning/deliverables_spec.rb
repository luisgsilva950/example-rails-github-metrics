# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning::Deliverables", type: :request do
  describe "GET /planning/deliverables" do
    it "returns a successful response" do
      get planning_deliverables_path
      expect(response).to have_http_status(:ok)
    end

    it "displays existing deliverables" do
      create(:deliverable, title: "Build auth module")
      get planning_deliverables_path
      expect(response.body).to include("Build auth module")
    end

    it "filters by status" do
      create(:deliverable, title: "Done task", status: "done")
      create(:deliverable, title: "Backlog task", status: "backlog")
      get planning_deliverables_path, params: { status: "done" }
      expect(response.body).to include("Done task")
      expect(response.body).not_to include("Backlog task")
    end
  end

  describe "GET /planning/deliverables/new" do
    it "returns a successful response" do
      get new_planning_deliverable_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /planning/deliverables" do
    let(:team) { create(:team) }

    let(:valid_params) do
      {
        deliverable: {
          team_id: team.id,
          title: "Implement SSO",
          specific_stack: "backend",
          total_effort_hours: 24,
          priority: 1,
          status: "backlog"
        }
      }
    end

    it "creates a deliverable with valid params" do
      expect {
        post planning_deliverables_path, params: valid_params
      }.to change(Deliverable, :count).by(1)

      expect(response).to redirect_to(planning_deliverables_path)
    end

    it "re-renders form with invalid params" do
      post planning_deliverables_path, params: { deliverable: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /planning/deliverables/:id/edit" do
    it "returns a successful response" do
      deliverable = create(:deliverable)
      get edit_planning_deliverable_path(deliverable)
      expect(response).to have_http_status(:ok)
    end

    it "displays the deliverable form with current values" do
      deliverable = create(:deliverable, title: "Build API")
      get edit_planning_deliverable_path(deliverable)
      expect(response.body).to include("Build API")
      expect(response.body).to include("Update Deliverable")
    end
  end

  describe "PATCH /planning/deliverables/:id" do
    let(:deliverable) { create(:deliverable, title: "Old Title") }

    it "updates the deliverable with valid params" do
      patch planning_deliverable_path(deliverable), params: { deliverable: { title: "New Title" } }

      expect(response).to redirect_to(planning_deliverables_path)
      expect(deliverable.reload.title).to eq("New Title")
    end

    it "re-renders edit form with invalid params" do
      patch planning_deliverable_path(deliverable), params: { deliverable: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
