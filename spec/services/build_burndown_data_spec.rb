# frozen_string_literal: true

require "rails_helper"

RSpec.describe BuildBurndownData do
  let(:monday) { Date.new(2025, 1, 6) }
  let(:friday) { Date.new(2025, 1, 10) }

  let(:team) { create(:team) }
  let(:cycle) { create(:cycle, start_date: monday, end_date: friday) }
  let(:developer) { create(:developer, team: team) }

  let(:deliverable) do
    create(:deliverable, cycle: cycle, team: team, total_effort_hours: 40.0)
  end

  subject(:builder) { described_class.new }

  describe "#call" do
    context "with a full-week allocation" do
      before do
        create(:deliverable_allocation,
               deliverable: deliverable,
               developer: developer,
               start_date: monday,
               end_date: friday)
        create(:developer_cycle_capacity, developer: developer, cycle: cycle)
      end

      it "returns ideal, planned, and executed keys" do
        result = builder.call(deliverable: deliverable, cycle: cycle)

        expect(result).to have_key(:ideal)
        expect(result).to have_key(:planned)
        expect(result).to have_key(:executed)
      end

      it "ideal line decreases linearly to zero" do
        result = builder.call(deliverable: deliverable, cycle: cycle)

        ideal = result[:ideal]
        expect(ideal.size).to eq(5)
        expect(ideal.first[:remaining]).to eq(32.0)
        expect(ideal.last[:remaining]).to eq(0.0)
      end

      it "planned line reflects actual allocations" do
        result = builder.call(deliverable: deliverable, cycle: cycle)

        planned = result[:planned]
        remaining = planned.map { |p| p[:remaining] }
        expect(remaining).to eq([ 32.0, 24.0, 16.0, 8.0, 0.0 ])
      end

      it "executed equals planned when no entries exist" do
        result = builder.call(deliverable: deliverable, cycle: cycle)

        expect(result[:executed]).to eq(result[:planned])
      end

      it "executed diverges when burndown entries exist" do
        create(:burndown_entry, deliverable: deliverable, date: Date.new(2025, 1, 8), hours_burned: 0.0)

        result = builder.call(deliverable: deliverable, cycle: cycle)

        executed = result[:executed].map { |e| e[:remaining] }
        planned = result[:planned].map { |p| p[:remaining] }
        expect(executed).not_to eq(planned)
      end
    end

    context "with no allocations" do
      it "ideal still decreases but planned stays flat" do
        result = builder.call(deliverable: deliverable, cycle: cycle)

        planned = result[:planned]
        remaining = planned.map { |p| p[:remaining] }
        expect(remaining).to all(eq(40.0))

        ideal = result[:ideal]
        expect(ideal.last[:remaining]).to eq(0.0)
      end
    end

    context "with custom query injected" do
      it "uses the injected query" do
        fake_query = double("FakeQuery")
        allow(fake_query).to receive(:call).and_return({
          planned: [
            { date: "2025-01-06", remaining: 30.0 },
            { date: "2025-01-07", remaining: 20.0 }
          ],
          executed: [
            { date: "2025-01-06", remaining: 30.0 },
            { date: "2025-01-07", remaining: 20.0 }
          ]
        })

        service = described_class.new(query: fake_query)
        result = service.call(deliverable: deliverable, cycle: cycle)

        expect(result[:planned].size).to eq(2)
        expect(result[:ideal].size).to eq(2)
        expect(result[:executed].size).to eq(2)
      end
    end
  end
end
