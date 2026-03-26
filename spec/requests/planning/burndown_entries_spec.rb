# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning::BurndownEntries", type: :request do
  let(:team) { create(:team) }
  let(:cycle) { create(:cycle, start_date: Date.new(2025, 1, 6), end_date: Date.new(2025, 1, 10)) }
  let(:deliverable) { create(:deliverable, cycle: cycle, team: team) }
  let(:developer) { create(:developer, team: team) }

  describe "POST /planning/cycles/:cycle_id/burndown_entries" do
    let(:valid_params) do
      {
        burndown_entry: {
          deliverable_id: deliverable.id,
          developer_id: developer.id,
          date: "2025-01-07",
          hours_burned: 4.0,
          note: "Developer pulled to bug fix"
        }
      }
    end

    it "creates a burndown entry scoped to a developer" do
      post planning_cycle_burndown_entries_path(cycle),
           params: valid_params,
           as: :json

      expect(response).to have_http_status(:created)
      expect(BurndownEntry.count).to eq(1)

      entry = BurndownEntry.last
      expect(entry.deliverable).to eq(deliverable)
      expect(entry.developer).to eq(developer)
      expect(entry.date).to eq(Date.new(2025, 1, 7))
      expect(entry.hours_burned).to eq(4.0)
      expect(entry.note).to eq("Developer pulled to bug fix")
    end

    it "returns errors for invalid data" do
      post planning_cycle_burndown_entries_path(cycle),
           params: { burndown_entry: { deliverable_id: deliverable.id, developer_id: developer.id, date: nil, hours_burned: -1 } },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.parsed_body
      expect(body["errors"]).to be_present
    end

    it "rejects duplicate date for same deliverable and developer" do
      create(:burndown_entry, deliverable: deliverable, developer: developer, date: Date.new(2025, 1, 7))

      post planning_cycle_burndown_entries_path(cycle),
           params: valid_params,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "allows same deliverable and date for different developers" do
      other_dev = create(:developer, team: team)
      create(:burndown_entry, deliverable: deliverable, developer: other_dev, date: Date.new(2025, 1, 7))

      post planning_cycle_burndown_entries_path(cycle),
           params: valid_params,
           as: :json

      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /planning/cycles/:cycle_id/burndown_entries/:id" do
    let!(:entry) { create(:burndown_entry, deliverable: deliverable, date: Date.new(2025, 1, 7), hours_burned: 4.0) }

    it "updates the burndown entry" do
      patch planning_cycle_burndown_entry_path(cycle, entry),
            params: { burndown_entry: { hours_burned: 2.0 } },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(entry.reload.hours_burned).to eq(2.0)
    end
  end

  describe "DELETE /planning/cycles/:cycle_id/burndown_entries/:id" do
    let!(:entry) { create(:burndown_entry, deliverable: deliverable, date: Date.new(2025, 1, 7)) }

    it "destroys the burndown entry" do
      delete planning_cycle_burndown_entry_path(cycle, entry), as: :json

      expect(response).to have_http_status(:no_content)
      expect(BurndownEntry.count).to eq(0)
    end
  end
end
