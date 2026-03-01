# frozen_string_literal: true

require "rails_helper"

RSpec.describe Holiday do
  describe "validations" do
    it "is valid with valid attributes" do
      holiday = build(:holiday)
      expect(holiday).to be_valid
    end

    it "requires a date" do
      holiday = build(:holiday, date: nil)
      expect(holiday).not_to be_valid
    end

    it "requires a name" do
      holiday = build(:holiday, name: nil)
      expect(holiday).not_to be_valid
    end

    it "requires a unique date" do
      create(:holiday, date: Date.new(2026, 4, 21))
      dup = build(:holiday, date: Date.new(2026, 4, 21))
      expect(dup).not_to be_valid
    end

    it "rejects invalid scope" do
      holiday = build(:holiday, scope: "state")
      expect(holiday).not_to be_valid
    end

    it "accepts national scope" do
      holiday = build(:holiday, scope: "national")
      expect(holiday).to be_valid
    end

    it "accepts municipal scope" do
      holiday = build(:holiday, scope: "municipal")
      expect(holiday).to be_valid
    end
  end

  describe ".between" do
    it "returns holidays within the range" do
      h1 = create(:holiday, date: Date.new(2026, 4, 21))
      create(:holiday, date: Date.new(2026, 12, 25))

      result = described_class.between(Date.new(2026, 4, 1), Date.new(2026, 4, 30))
      expect(result).to contain_exactly(h1)
    end
  end

  describe ".dates_between" do
    it "returns a set of dates" do
      create(:holiday, date: Date.new(2026, 4, 21))
      create(:holiday, date: Date.new(2026, 5, 1))

      result = described_class.dates_between(Date.new(2026, 4, 1), Date.new(2026, 5, 31))
      expect(result).to be_a(Set)
      expect(result).to include(Date.new(2026, 4, 21), Date.new(2026, 5, 1))
    end
  end
end
