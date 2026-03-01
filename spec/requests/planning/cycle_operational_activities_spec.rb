# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning::CycleOperationalActivities", type: :request do
  let(:cycle) { create(:cycle, start_date: Date.new(2026, 2, 23), end_date: Date.new(2026, 3, 6)) }

  describe "POST /planning/cycles/:cycle_id/cycle_operational_activities" do
    let(:valid_params) do
      {
        cycle_operational_activity: {
          name: "bugs",
          start_date: "2026-02-25",
          end_date: "2026-02-27"
        }
      }
    end

    it "creates a team-wide operational activity" do
      post planning_cycle_cycle_operational_activities_path(cycle), params: valid_params

      expect(CycleOperationalActivity.count).to eq(1)
      activity = CycleOperationalActivity.last
      expect(activity.name).to eq("bugs")
      expect(activity.start_date).to eq(Date.new(2026, 2, 25))
      expect(activity.end_date).to eq(Date.new(2026, 2, 27))
      expect(activity.color).to eq("#ef4444")
      expect(activity.cycle).to eq(cycle)
      expect(activity.developer).to be_nil
      expect(response).to redirect_to(plan_planning_cycle_path(cycle, anchor: "operational-activities"))
    end

    it "creates a developer-specific operational activity" do
      developer = create(:developer)
      post planning_cycle_cycle_operational_activities_path(cycle), params: {
        cycle_operational_activity: {
          name: "refinement",
          developer_id: developer.id,
          start_date: "2026-03-02",
          end_date: "2026-03-04"
        }
      }

      activity = CycleOperationalActivity.last
      expect(activity.developer).to eq(developer)
      expect(activity.start_date).to eq(Date.new(2026, 3, 2))
    end

    it "redirects with alert on invalid params" do
      post planning_cycle_cycle_operational_activities_path(cycle), params: {
        cycle_operational_activity: { name: "", start_date: "", end_date: "" }
      }

      expect(response).to redirect_to(plan_planning_cycle_path(cycle, anchor: "operational-activities"))
      expect(flash[:alert]).to be_present
    end

    it "allows multiple activities with overlapping dates" do
      post planning_cycle_cycle_operational_activities_path(cycle), params: valid_params
      post planning_cycle_cycle_operational_activities_path(cycle), params: {
        cycle_operational_activity: { name: "refinement", start_date: "2026-02-25", end_date: "2026-02-25" }
      }

      expect(CycleOperationalActivity.count).to eq(2)
    end

    context "recurring mode" do
      it "creates one record per occurrence of the selected weekday" do
        # Cycle: Mon Feb 23 – Fri Mar 6 => Wednesdays: Feb 25, Mar 4 = 2 records
        post planning_cycle_cycle_operational_activities_path(cycle), params: {
          cycle_operational_activity: {
            name: "bugs",
            recurrence_day: "3"
          }
        }

        expect(CycleOperationalActivity.count).to eq(2)
        dates = CycleOperationalActivity.order(:start_date).pluck(:start_date)
        expect(dates).to eq([Date.new(2026, 2, 25), Date.new(2026, 3, 4)])
        expect(CycleOperationalActivity.first.end_date).to eq(CycleOperationalActivity.first.start_date)
        expect(response).to redirect_to(plan_planning_cycle_path(cycle, anchor: "operational-activities"))
        expect(flash[:notice]).to include("2 recurring")
      end

      it "creates recurring activities for a specific developer" do
        developer = create(:developer)
        post planning_cycle_cycle_operational_activities_path(cycle), params: {
          cycle_operational_activity: {
            name: "study",
            recurrence_day: "5",
            developer_id: developer.id
          }
        }

        # Fridays in cycle: Feb 27, Mar 6 = 2 records
        expect(CycleOperationalActivity.count).to eq(2)
        expect(CycleOperationalActivity.all.map(&:developer_id).uniq).to eq([developer.id])
      end

      it "redirects with alert when no matching weekdays found" do
        short_cycle = create(:cycle, start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 3))
        # Mon-Tue, no Wednesday
        post planning_cycle_cycle_operational_activities_path(short_cycle), params: {
          cycle_operational_activity: {
            name: "bugs",
            recurrence_day: "3"
          }
        }

        expect(CycleOperationalActivity.count).to eq(0)
        expect(flash[:alert]).to include("No matching weekdays")
      end
    end
  end

  describe "DELETE /planning/cycles/:cycle_id/cycle_operational_activities/:id" do
    it "destroys the operational activity" do
      activity = create(:cycle_operational_activity, cycle: cycle)

      delete planning_cycle_cycle_operational_activity_path(cycle, activity)

      expect(CycleOperationalActivity.count).to eq(0)
      expect(response).to redirect_to(plan_planning_cycle_path(cycle, anchor: "operational-activities"))
    end
  end
end
