# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeveloperCycleCapacity do
  subject(:capacity) { build(:developer_cycle_capacity) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires gross_hours >= 0" do
      capacity.gross_hours = -1
      expect(capacity).not_to be_valid
    end

    it "enforces uniqueness of developer per cycle" do
      existing = create(:developer_cycle_capacity)
      duplicate = build(:developer_cycle_capacity,
                        developer: existing.developer,
                        cycle: existing.cycle)
      expect(duplicate).not_to be_valid
    end
  end
end
