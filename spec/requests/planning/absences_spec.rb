# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning::Absences", type: :request do
  let(:developer) { create(:developer) }

  describe "POST /planning/developers/:developer_id/absences" do
    let(:valid_params) do
      {
        absence: {
          start_date: "2026-03-09",
          end_date: "2026-03-13",
          reason: "Vacation"
        }
      }
    end

    it "creates an absence with valid params" do
      expect {
        post planning_developer_absences_path(developer), params: valid_params
      }.to change(Absence, :count).by(1)

      expect(response).to redirect_to(planning_developer_path(developer))
      follow_redirect!
      expect(response.body).to include("Absence added.")
    end

    it "redirects with alert when end_date before start_date" do
      post planning_developer_absences_path(developer), params: {
        absence: { start_date: "2026-03-13", end_date: "2026-03-09", reason: "Invalid" }
      }

      expect(response).to redirect_to(planning_developer_path(developer))
      follow_redirect!
      expect(response.body).to include("must be on or after start date")
    end

    it "associates the absence with the correct developer" do
      post planning_developer_absences_path(developer), params: valid_params

      absence = Absence.last
      expect(absence.developer).to eq(developer)
      expect(absence.start_date).to eq(Date.new(2026, 3, 9))
      expect(absence.end_date).to eq(Date.new(2026, 3, 13))
      expect(absence.reason).to eq("Vacation")
    end
  end

  describe "DELETE /planning/developers/:developer_id/absences/:id" do
    it "destroys the absence" do
      absence = create(:absence, developer: developer)

      expect {
        delete planning_developer_absence_path(developer, absence)
      }.to change(Absence, :count).by(-1)

      expect(response).to redirect_to(planning_developer_path(developer))
    end
  end
end
