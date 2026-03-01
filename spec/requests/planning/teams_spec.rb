# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning::Teams", type: :request do
  describe "GET /planning/teams" do
    it "returns a successful response" do
      get planning_teams_path
      expect(response).to have_http_status(:ok)
    end

    it "displays existing teams" do
      create(:team, name: "Digital Farm")
      get planning_teams_path
      expect(response.body).to include("Digital Farm")
    end
  end

  describe "GET /planning/teams/new" do
    it "returns a successful response" do
      get new_planning_team_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /planning/teams" do
    it "creates a team with valid params" do
      expect {
        post planning_teams_path, params: { team: { name: "Alpha Squad" } }
      }.to change(Team, :count).by(1)

      expect(response).to redirect_to(planning_teams_path)
    end

    it "re-renders form with invalid params" do
      post planning_teams_path, params: { team: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /planning/teams/:id/edit" do
    it "returns a successful response" do
      team = create(:team)
      get edit_planning_team_path(team)
      expect(response).to have_http_status(:ok)
    end

    it "displays the team form with current values" do
      team = create(:team, name: "Alpha Squad")
      get edit_planning_team_path(team)
      expect(response.body).to include("Alpha Squad")
      expect(response.body).to include("Update Team")
    end
  end

  describe "PATCH /planning/teams/:id" do
    let(:team) { create(:team, name: "Old Name") }

    it "updates the team with valid params" do
      patch planning_team_path(team), params: { team: { name: "New Name" } }

      expect(response).to redirect_to(planning_teams_path)
      expect(team.reload.name).to eq("New Name")
    end

    it "re-renders edit form with invalid params" do
      patch planning_team_path(team), params: { team: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
