# frozen_string_literal: true

require "rails_helper"

RSpec.describe CycleOperationalActivity, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      activity = build(:cycle_operational_activity)
      expect(activity).to be_valid
    end

    it "requires a name" do
      activity = build(:cycle_operational_activity, name: nil)
      expect(activity).not_to be_valid
      expect(activity.errors[:name]).to include("can't be blank")
    end

    it "rejects invalid name values" do
      activity = build(:cycle_operational_activity)
      activity.name = "invalid"
      expect(activity).not_to be_valid
      expect(activity.errors[:name]).to include("is not included in the list")
    end

    it "accepts valid enum values" do
      %w[bugs refinement study].each do |type|
        activity = build(:cycle_operational_activity, name: type)
        expect(activity).to be_valid
      end
    end

    it "assigns color automatically based on activity type" do
      activity = build(:cycle_operational_activity, name: "bugs", color: nil)
      activity.valid?
      expect(activity.color).to eq("#ef4444")
    end

    it "assigns correct color for refinement" do
      activity = build(:cycle_operational_activity, name: "refinement", color: nil)
      activity.valid?
      expect(activity.color).to eq("#8b5cf6")
    end

    it "assigns correct color for study" do
      activity = build(:cycle_operational_activity, name: "study", color: nil)
      activity.valid?
      expect(activity.color).to eq("#3b82f6")
    end

    it "requires a start_date" do
      activity = build(:cycle_operational_activity, start_date: nil)
      expect(activity).not_to be_valid
    end

    it "requires an end_date" do
      activity = build(:cycle_operational_activity, end_date: nil)
      expect(activity).not_to be_valid
    end

    it "rejects end_date before start_date" do
      activity = build(:cycle_operational_activity,
                       start_date: Date.new(2026, 2, 25),
                       end_date: Date.new(2026, 2, 24))
      expect(activity).not_to be_valid
      expect(activity.errors[:end_date]).to include("must be on or after start date")
    end

    it "allows end_date equal to start_date (single day)" do
      activity = build(:cycle_operational_activity,
                       start_date: Date.new(2026, 2, 25),
                       end_date: Date.new(2026, 2, 25))
      expect(activity).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a cycle" do
      activity = create(:cycle_operational_activity)
      expect(activity.cycle).to be_a(Cycle)
    end

    it "optionally belongs to a developer" do
      developer = create(:developer)
      activity = create(:cycle_operational_activity, developer: developer)
      expect(activity.developer).to eq(developer)
    end

    it "is team-wide when developer is nil" do
      activity = build(:cycle_operational_activity, developer: nil)
      expect(activity.team_wide?).to be true
    end
  end

  describe "#work_days" do
    it "counts weekdays in the date range" do
      # Mon Feb 23 to Fri Feb 27 = 5 work days
      activity = build(:cycle_operational_activity,
                       start_date: Date.new(2026, 2, 23),
                       end_date: Date.new(2026, 2, 27))
      expect(activity.work_days).to eq(5)
    end

    it "excludes holidays" do
      create(:holiday, date: Date.new(2026, 2, 25))
      activity = build(:cycle_operational_activity,
                       start_date: Date.new(2026, 2, 23),
                       end_date: Date.new(2026, 2, 27))
      expect(activity.work_days).to eq(4)
    end
  end

  describe ".ordered" do
    it "orders by start_date" do
      cycle = create(:cycle)
      late = create(:cycle_operational_activity, cycle: cycle, name: "study",
                    start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 4))
      early = create(:cycle_operational_activity, cycle: cycle, name: "bugs",
                     start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 27))

      expect(cycle.cycle_operational_activities.ordered).to eq([early, late])
    end
  end

  describe ".for_developer" do
    it "returns team-wide activities and developer-specific ones" do
      cycle = create(:cycle)
      developer = create(:developer)
      team_wide = create(:cycle_operational_activity, cycle: cycle, developer: nil)
      specific = create(:cycle_operational_activity, cycle: cycle, developer: developer,
                        name: "study", start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 4))
      other_dev = create(:developer)
      create(:cycle_operational_activity, cycle: cycle, developer: other_dev,
             name: "refinement", start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 4))

      result = cycle.cycle_operational_activities.for_developer(developer.id)
      expect(result).to contain_exactly(team_wide, specific)
    end
  end

  describe ".overlapping" do
    it "returns activities overlapping the given range" do
      cycle = create(:cycle)
      inside = create(:cycle_operational_activity, cycle: cycle,
                      start_date: Date.new(2026, 2, 25), end_date: Date.new(2026, 2, 27))
      outside = create(:cycle_operational_activity, cycle: cycle, name: "study",
                       start_date: Date.new(2026, 3, 9), end_date: Date.new(2026, 3, 10))

      result = cycle.cycle_operational_activities.overlapping(Date.new(2026, 2, 23), Date.new(2026, 2, 28))
      expect(result).to contain_exactly(inside)
    end
  end
end
