# frozen_string_literal: true

require "rails_helper"

RSpec.describe BurndownQuery do
  # Use a fixed Monday-to-Friday week to avoid weekend issues
  let(:monday) { Date.new(2025, 1, 6) }
  let(:friday) { Date.new(2025, 1, 10) }

  let(:team) { create(:team) }
  let(:cycle) { create(:cycle, start_date: monday, end_date: friday) }
  let(:developer) { create(:developer, team: team) }

  let(:deliverable) do
    create(:deliverable, cycle: cycle, team: team, total_effort_hours: 40.0)
  end

  subject(:query) { described_class.new(holiday_dates: holiday_dates) }

  let(:holiday_dates) { [] }

  describe "#call" do
    context "with no allocations" do
      it "returns planned entries per work day with remaining equal to total effort" do
        result = query.call(deliverable: deliverable, cycle: cycle)

        expect(result[:planned].size).to eq(5)
        expect(result[:planned].map { |r| r[:remaining] }).to all(eq(40.0))
      end

      it "returns executed equal to planned when no entries exist" do
        result = query.call(deliverable: deliverable, cycle: cycle)

        expect(result[:executed]).to eq(result[:planned])
      end
    end

    context "with a full-week allocation" do
      before do
        create(:deliverable_allocation,
               deliverable: deliverable,
               developer: developer,
               start_date: monday,
               end_date: friday)
        create(:developer_cycle_capacity, developer: developer, cycle: cycle)
      end

      it "burns 8h per day in planned series" do
        result = query.call(deliverable: deliverable, cycle: cycle)

        remaining = result[:planned].map { |r| r[:remaining] }
        expect(remaining).to eq([ 32.0, 24.0, 16.0, 8.0, 0.0 ])
      end

      it "returns dates as strings" do
        result = query.call(deliverable: deliverable, cycle: cycle)

        expect(result[:planned].first[:date]).to eq(monday.to_s)
        expect(result[:planned].last[:date]).to eq(friday.to_s)
      end
    end

    context "with a partial allocation" do
      before do
        create(:deliverable_allocation,
               deliverable: deliverable,
               developer: developer,
               start_date: Date.new(2025, 1, 8),
               end_date: Date.new(2025, 1, 10))
        create(:developer_cycle_capacity, developer: developer, cycle: cycle)
      end

      it "only burns hours on allocated days" do
        result = query.call(deliverable: deliverable, cycle: cycle)

        remaining = result[:planned].map { |r| r[:remaining] }
        expect(remaining).to eq([ 40.0, 40.0, 32.0, 24.0, 16.0 ])
      end
    end

    context "with holidays" do
      let(:holiday_dates) { [ Date.new(2025, 1, 8) ] }

      before do
        create(:deliverable_allocation,
               deliverable: deliverable,
               developer: developer,
               start_date: monday,
               end_date: friday)
        create(:developer_cycle_capacity, developer: developer, cycle: cycle)
      end

      it "skips holiday dates" do
        result = query.call(deliverable: deliverable, cycle: cycle)

        dates = result[:planned].map { |r| r[:date] }
        expect(dates).not_to include("2025-01-08")
        expect(result[:planned].size).to eq(4)
      end
    end

    context "with multiple developers allocated" do
      let(:developer2) { create(:developer, team: team) }

      before do
        create(:deliverable_allocation,
               deliverable: deliverable,
               developer: developer,
               start_date: monday,
               end_date: friday)
        create(:deliverable_allocation,
               deliverable: deliverable,
               developer: developer2,
               start_date: monday,
               end_date: friday)
        create(:developer_cycle_capacity, developer: developer, cycle: cycle)
        create(:developer_cycle_capacity, developer: developer2, cycle: cycle)
      end

      it "burns 16h per day with two developers" do
        result = query.call(deliverable: deliverable, cycle: cycle)

        remaining = result[:planned].map { |r| r[:remaining] }
        expect(remaining).to eq([ 24.0, 8.0, -8.0, -24.0, -40.0 ])
      end
    end

    context "with a single-day cycle" do
      let(:single_day_cycle) { create(:cycle, start_date: monday, end_date: monday + 1.day) }

      it "returns work days within the cycle" do
        deliverable.update!(cycle: single_day_cycle)
        result = query.call(deliverable: deliverable, cycle: single_day_cycle)

        expect(result[:planned].size).to eq(2)
      end
    end

    context "with burndown entries overriding execution" do
      before do
        create(:deliverable_allocation,
               deliverable: deliverable,
               developer: developer,
               start_date: monday,
               end_date: friday)
        create(:developer_cycle_capacity, developer: developer, cycle: cycle)
      end

      it "uses entry hours_burned instead of planned for that day" do
        create(:burndown_entry, deliverable: deliverable, date: Date.new(2025, 1, 7), hours_burned: 2.0)

        result = query.call(deliverable: deliverable, cycle: cycle)

        executed_remaining = result[:executed].map { |r| r[:remaining] }
        # Day 1: 40-8=32, Day 2: 32-2=30 (overridden), Day 3: 30-8=22, Day 4: 22-8=14, Day 5: 14-8=6
        expect(executed_remaining).to eq([ 32.0, 30.0, 22.0, 14.0, 6.0 ])
      end

      it "planned series is unaffected by entries" do
        create(:burndown_entry, deliverable: deliverable, date: Date.new(2025, 1, 7), hours_burned: 0.0)

        result = query.call(deliverable: deliverable, cycle: cycle)

        planned_remaining = result[:planned].map { |r| r[:remaining] }
        expect(planned_remaining).to eq([ 32.0, 24.0, 16.0, 8.0, 0.0 ])
      end

      it "handles zero hours burned (developer fully pulled away)" do
        create(:burndown_entry, deliverable: deliverable, date: Date.new(2025, 1, 7), hours_burned: 0.0)

        result = query.call(deliverable: deliverable, cycle: cycle)

        executed_remaining = result[:executed].map { |r| r[:remaining] }
        # Day 1: 40-8=32, Day 2: 32-0=32, Day 3: 32-8=24, Day 4: 24-8=16, Day 5: 16-8=8
        expect(executed_remaining).to eq([ 32.0, 32.0, 24.0, 16.0, 8.0 ])
      end
    end
  end
end
