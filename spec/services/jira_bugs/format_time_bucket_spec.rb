# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugs::FormatTimeBucket do
  describe "#bucket" do
    it "buckets daily" do
      bucket = described_class.new(group_by: "daily")
      time = Time.zone.parse("2026-02-18 14:00:00")

      expect(bucket.bucket(time)).to eq("2026-02-18")
    end

    it "buckets weekly (monday start)" do
      bucket = described_class.new(group_by: "weekly")
      time = Time.zone.parse("2026-02-18 14:00:00") # Wednesday

      expect(bucket.bucket(time)).to eq("2026-02-16")
    end

    it "buckets monthly" do
      bucket = described_class.new(group_by: "monthly")
      time = Time.zone.parse("2026-02-18 14:00:00")

      expect(bucket.bucket(time)).to eq("2026-02")
    end
  end

  describe "#format_label" do
    it "formats daily label" do
      bucket = described_class.new(group_by: "daily")

      expect(bucket.format_label("2026-02-18")).to eq("18/02/2026")
    end

    it "formats weekly label with range" do
      bucket = described_class.new(group_by: "weekly")

      expect(bucket.format_label("2026-02-16")).to eq("16/02 – 22/02")
    end

    it "formats monthly label" do
      bucket = described_class.new(group_by: "monthly")

      expect(bucket.format_label("2026-02")).to eq("Feb 2026")
    end
  end
end
