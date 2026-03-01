# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthorNameMappings do
  describe "#to_h" do
    it "parses variant:Canonical pairs from raw mapping" do
      mappings = described_class.new(raw_mapping: "jdoe:Jane Doe,j doe:Jane Doe")

      expect(mappings.to_h).to eq({
        "jdoe" => "Jane Doe",
        "j doe" => "Jane Doe"
      })
    end

    it "returns empty hash for blank mapping" do
      mappings = described_class.new(raw_mapping: "")

      expect(mappings.to_h).to eq({})
    end

    it "returns empty hash for whitespace-only mapping" do
      mappings = described_class.new(raw_mapping: "   ")

      expect(mappings.to_h).to eq({})
    end

    it "ignores invalid entries without colon" do
      mappings = described_class.new(raw_mapping: "valid:Name,invalid_entry")

      expect(mappings.to_h).to eq({ "valid" => "Name" })
    end

    it "downcases the variant key" do
      mappings = described_class.new(raw_mapping: "JDoe:Jane Doe")

      expect(mappings.to_h).to have_key("jdoe")
    end

    it "strips whitespace from keys and values" do
      mappings = described_class.new(raw_mapping: " jdoe : Jane Doe ")

      expect(mappings.to_h).to eq({ "jdoe" => "Jane Doe" })
    end

    it "handles colons in canonical name" do
      mappings = described_class.new(raw_mapping: "alias:Name:With:Colons")

      expect(mappings.to_h).to eq({ "alias" => "Name:With:Colons" })
    end

    it "memoizes the result" do
      mappings = described_class.new(raw_mapping: "a:B")

      expect(mappings.to_h).to equal(mappings.to_h)
    end
  end
end

RSpec.describe AuthorNameNormalizer do
  describe "#call" do
    subject(:normalizer) { described_class.new(mappings: mappings) }

    let(:mappings) { AuthorNameMappings.new(raw_mapping: "jdoe:Jane Doe,j. doe:Jane Doe") }

    it "normalizes name to lowercase" do
      expect(normalizer.call("John Smith")).to eq("john smith")
    end

    it "returns nil for nil input" do
      expect(normalizer.call(nil)).to be_nil
    end

    it "strips whitespace" do
      expect(normalizer.call("  John Smith  ")).to eq("john smith")
    end

    it "uses canonical mapping when variant matches" do
      expect(normalizer.call("jdoe")).to eq("jane doe")
    end

    it "matches variant case-insensitively" do
      expect(normalizer.call("JDoe")).to eq("jane doe")
    end

    it "uses canonical mapping with periods" do
      expect(normalizer.call("J. Doe")).to eq("jane doe")
    end

    it "returns lowercase original when no mapping found" do
      expect(normalizer.call("Unknown Author")).to eq("unknown author")
    end

    it "works with default (empty) mappings" do
      normalizer = described_class.new

      expect(normalizer.call("Some Author")).to eq("some author")
    end
  end
end
