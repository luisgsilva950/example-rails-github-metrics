# frozen_string_literal: true

require "rails_helper"

RSpec.describe Developer do
  subject(:developer) { build(:developer) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires a name" do
      developer.name = nil
      expect(developer).not_to be_valid
    end

    it "requires a valid domain_stack" do
      developer.domain_stack = "cobol"
      expect(developer).not_to be_valid
    end

    it "requires a valid seniority" do
      developer.seniority = "intern"
      expect(developer).not_to be_valid
    end

    it "requires productivity_factor > 0" do
      developer.productivity_factor = 0
      expect(developer).not_to be_valid
    end

    it "requires productivity_factor <= 1" do
      developer.productivity_factor = 1.5
      expect(developer).not_to be_valid
    end
  end

  describe "scopes" do
    it ".by_stack filters by domain_stack" do
      be_dev = create(:developer, domain_stack: "backend")
      create(:developer, domain_stack: "frontend")
      expect(described_class.by_stack("backend")).to eq([ be_dev ])
    end

    it ".by_seniority filters by seniority" do
      senior = create(:developer, seniority: "senior")
      create(:developer, seniority: "junior")
      expect(described_class.by_seniority("senior")).to eq([ senior ])
    end
  end
end
